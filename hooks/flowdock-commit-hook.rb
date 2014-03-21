# Copyright (c) 2012 Flowdock Ltd, http://www.flowdock.com/

#############################
### CONFIG SECTION STARTS ###
#############################

FLOWDOCK_TOKEN = ""
REPOSITORY_NAME = nil
REPOSITORY_URL = nil # "https://svn.example.com/repository/trunk"
REVISION_URL = nil # "https://svn.example.com/repository/trunk?p=:revision"
VERIFY_SSL = true
USERS = {
  # '<svn username>' => { 'name' => 'John Doe', 'email' => 'user@email.address' },
}

###########################
### CONFIG SECTION ENDS ###
###########################

if FLOWDOCK_TOKEN.nil? || !FLOWDOCK_TOKEN.match(/^[a-z0-9]+$/)
  puts "Flowdock token missing or invalid"
  exit 1
end

REPOSITORY_PATH = ARGV[0]
REVISION = ARGV[1].to_i

require 'rubygems'
require 'net/https'
require 'svn'
require 'multi_json'

class Revision
  def initialize(repository_path, rev)
    @repository_name = REPOSITORY_NAME || repository_path.split('/').last
    @repository = Svn::Repo.open(repository_path)
    @revision = @repository.revision(rev)
    @changes = {
      'added' => [],
      'removed' => [],
      'modified' => []
    }
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
      'author' => USERS[@revision.author] || { 'name' => @revision.author },
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
      match = path.match(/^\/(?:(trunk)|branches\/(\w+))(?:\/(.*))?/) || [nil]

      set_branch_and_action!(path, match, change)

      change_kind = change.change_kind.to_s
      change_kind = 'removed' if change_kind == 'deleted'

      @changes[change_kind] << {
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
        'branch_create'
      elsif change.change_kind == :deleted
        'branch_delete'
      else
        'commit'
      end
    end
    @action ||= 'commit'
  end
end

revision = Revision.new(REPOSITORY_PATH, REVISION)

request = Net::HTTP::Post.new("/svn/#{FLOWDOCK_TOKEN}")
request.body = MultiJson.encode({ :payload => revision.to_hash })
request.content_type = 'application/json'

http = Net::HTTP.new('api.flowdock.com', 443)
http.use_ssl = true
http.verify_mode = if VERIFY_SSL
  OpenSSL::SSL::VERIFY_PEER
else
  OpenSSL::SSL::VERIFY_NONE
end
response = http.request(request)
