flowdock-svn-hook
=================

Subversion hook sending events to Flowdock

If you already know about Ruby and Subversion commit hooks,
[flowdock-commit-hook.rb](https://github.com/flowdock/flowdock-svn-hook/raw/master/hooks/flowdock-commit-hook.rb)
is what you are looking for.

### Requirements

This list of software needs to be available for the user you use to host
the repository.

* ruby - _1.8.7 and 1.9.x are supported_

  Install or update using your OS's package manager or follow the instructions
  at [http://www.ruby-lang.org/en/downloads/](http://www.ruby-lang.org/en/downloads/).
  Note, that using rvm could be tricky, because commit hooks are not run on
  [a real shell environment](http://svnbook.red-bean.com/en/1.1/ch05s02.html#svn-ch-5-sect-2.1)!

* rubygems - _only for 1.8.7, rubygems is included in standard 1.9.x ruby_

  Follow the installation instructions at [https://rubygems.org/pages/download](https://rubygems.org/pages/download).

  TL;DR; Currently:

        wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.24.zip
        unzip rubygems-1.8.24.zip
        cd rubygems-1.8.24
        ruby setup.rb

* svn and multi_json gems

        gem install svn multi_json --no-ri --no-rdoc

  NOTE: Current version of svn gem (0.2.0) is broken on MacOSX, you need to
  install the gem manually from Github source.

### Install

Find out where your repository is located in the filesystem. We'll refer it's
`hooks` subdirectory as HOOKS_DIR later on.

Copy [flowdock-commit-hook.rb](https://github.com/flowdock/flowdock-svn-hook/raw/master/hooks/flowdock-commit-hook.rb)
to your HOOKS_DIR.

Change the configuration variables in the beginning of the file:

* FLOWDOCK_TOKEN (mandatory)

  Log in and pick your flow token from [https://www.flowdock.com/account/tokens](https://www.flowdock.com/account/tokens)
  under "Flow API tokens".

* REPOSITORY_NAME (optional)

  Used in Team Inbox as a source name. If it's nil, then the directory name of
  the repository is used (`/var/www/repos/foo` will show up as `foo`).

* REPOSITORY_URL (optional)

  Used in Team Inbox as a link to project source.
  Eg. `https://svn.example.com/repository/trunk`

* REVISION_URL (optional)

  Used in Team Inbox message as a link to a specific revision. A string
  `:revision` is replaced with the revision number. Eg.
  `http://svn.example.com/repo/trunk?p=:revision` with r1234 becomes a link to
  `http://svn.example.com/repo/trunk?p=1234` in Flowdock Team Inbox.

* USERS (optional)

  Map your Subversion usernames to real names and email addresses.
  Flowdock uses these to enrich your Team Inbox events' default content.

In case you don't yet have post commit scripts, you have to create the invoking
script:

    cat > HOOKS_DIR/post-commit <<EOF
    #!/bin/sh
    EOF
    chmod u+x HOOKS_DIR/post-commit

Add this line at the bottom of HOOKS_DIR/post-commit file

    ruby HOOKS_DIR/flowdock-commit-hook.rb "$1" "$2"

where 'ruby' is an absolute path to your installed ruby interpreter.

### Notes

To get the most out of the Flowdock post commit hook, we encourage you to
follow [SVN best practices](http://blog.evanweaver.com/2007/08/15/svn-branching-best-practices-in-practice/).

By the way, there is also a [Git](http://git-scm.org) SCM tool.
