#!/usr/bin/ruby

FLOWDOCK_TOKEN = ""
REPOSITORY_NAME = nil
REPOSITORY_URL = "https://svn.example.com/repository/trunk"
REVISION_URL = "https://svn.example.com/repository/trunk?p=:revision"

##############################
### DO NOT EDIT BELOW THIS ###
##############################

REPOSITORY_PATH = ARGV[0]
REVISION = ARGV[1].to_i

require 'rubygems'
require 'net/http'
require 'svn'
require 'multi_json'

class Revision
  def initialize(repository_path, rev)
    @repository_name = REPOSITORY_NAME || repository_path.split('/').last
    @repository = Svn::Repo.open(repository_path)
    @revision = @repository.revision(rev)
    @changes = []
    process_changes!
  end

  def to_hash
    {
      'repository' => {
        'name' => @repository_name,
        'url' => REPOSITORY_URL
      },
      'revision' => @revision.to_s,
      'revision_url' => REVISION_URL,
      'author' => @revision.author,
      'message' => @revision.message,
      'time' => @revision.timestamp.to_i,
      'branch' => @branch,
      'action' => @action,
      'changes' => @changes
    }
  end

  private

  def process_changes!
    @revision.changes.each_pair do |path, change|
      match = path.match(/^\/(?:(trunk)|branches\/(\w+))(?:\/(.*))?/)

      set_branch_and_action!(path, match, change)

      @changes << {
        'action' => change.change_kind.to_s,
        'file_type' => change.node_kind.to_s,
        'path' => (match && match[3] || path)
      }
    end
  end

  def set_branch_and_action!(path, match, change)
    if change.node_kind == :file
      @branch = match[1..2].compact.first
    elsif change.node_kind == :dir && path.start_with?('/branches/')
      @branch = match[2]
      @action = if change.change_kind == :added
        'branch create'
      elsif change.change_kind == :deleted
        'branch delete'
      else
        'commit'
      end
    else
      @branch = path
    end
    @action ||= 'commit'
  end
end

revision = Revision.new(REPOSITORY_PATH, REVISION)

request = Net::HTTP::Post.new("/svn/#{FLOWDOCK_TOKEN}")
request.body = MultiJson.encode({ :payload => revision.to_hash })
request.content_type = 'application/json'

flowdock_api_domain = ENV['FLOWDOCK_API_DOMAIN'] || 'api.flowdock.com'
flowdock_port = ENV['FLOWDOCK_PORT'] || 443

http = Net::HTTP.new(flowdock_api_domain, flowdock_port)
if flowdock_port == 443
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end
response = http.request(request)
