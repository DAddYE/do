# DO .. it! - Framework Toolkit for Sysadmin

DO is a thin framework useful to manage remote servers through ssh.

There are many other alternative, once of them is [capistrano](https://github.com/capistrano/capistrano)

So why another one? Basically I need:

* easy creation of my recipes
* see perfectly what's happening on my remote servers
* highly focus on smart actions, upload, download, sudo, replace.
* manage more than one server each
* use same behaviour for manage local tasks

## Installation

```sh
$ sudo gem install do
$ doit do:setup
```

Now start to edit your `~/do/dorc` file and have fun!

## Files

There are some way to generate **DO** tasks, you can:

* Create a file called `Do` in your project directory
* Create a file called `Dofile` in your project directory
* Create `*.rake` files in `~/.do` directory, aka **home dir**
* Create a file called `dorc` in `~/.do` directory

You can change your **do home directory** with:

```
DO_PATH='/my/new/.do/path'
ENV['DO_PATH']='/my/new/.do/path'
export DO_PATH='/my/new/.do/path'
```

## Features

* Easily server logging
* SSH connections
* SFTP connections (upload and download)
* run cmd (we handle also with input)
* shortcuts (exist?, read, replace, append etc...)

Code is much better:

```rb
server = DO::Server.new('srv1', 'srv1.domain.local', 'root', :key => %w[srv1.pem]

server.run 'uname'
# root@srv1 ~ # uname
# Linux

server.run 'uname', '-a'
# root@srv1 ~ # uname -a
# Linux srv1.lipsiasoft.net 2.6.18-194.32.1.el5  x86_64 x86_64 x86_64 GNU/Linux

server.run 'mysqladmin -u root -p password 'oldone', 'newpassword'
# root@srv1 ~ # mysqladmin -u root -p password 'oldone'
# Enter password: oldone
# mysqladmin: connect to server at 'localhost' failed
# error: 'Access denied for user 'root'@'localhost' (using password: YES)'

server.exist?('~/.ssh')
# root@srv1 ~ # test -e ~/.ssh && echo True
# => true

server.read('/etc/redhat-release')
# root@srv1 ~ # cat /etc/redhat-release
# => "CentOS release 5.5 (Final)"

server.upload '/tmp/file', '/tmp/foo'
# root@srv1 ~ # upload from '/tmp/file' to '/tmp/foo'

server.download '/tmp/foo', '/tmp/file2'
# root@srv1 ~ # download from '/tmp/foo' to '/tmp/file2'

server.replace :all, 'new content', '/tmp/file'
# root@srv1 ~ # replace all in '/tmp/foo'

server.read('/tmp/foo')
# root@srv1 ~ # cat /tmp/foo
# => "new content"

server.replace /content$/, 'changed content', '/tmp/foo'
# root@srv1 ~ # replace /content$/ in '/tmp/foo'

server.read('/tmp/foo')
# root@srv1 ~ # cat /tmp/foo
# => "new changed content"

server.append('appended', '/tmp/foo')
# root@srv1 ~ # append to 'bottom' in '/tmp/foo'

server.read('/tmp/foo')
# root@srv1 ~ # cat /tmp/foo
# => "new changed contentappended"

server.append('---', '/tmp/foo', :top)
# root@srv1 ~ # append to 'top' in '/tmp/foo'

server.read('/tmp/foo')
# root@srv1 ~ # cat /tmp/foo
# => "---new changed contentappended"

server.ask "Please choose"
# root@srv1 ~ # Please choose: foo
# => "foo"

server.yes? "Do you want to proceed"
# root@srv1 ~ # Do you want to proceed? (y/n): y
# => 0

server.wait
# Press ENTER to continue...
```

## Scenario and examples

I'm porting my custom recipes to do, you can found my dot files
[here](https://github.com/daddye/.do)

I've server config in `~/.do/dorc`:

```rb
keys = %w(/keys/master.pem /keys/instances.pem /keys/stage.pem)
server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => keys
server :srv0, 'srv0.lipsiasoft.biz', 'root', :keys => keys
server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => keys
server :srv2, 'srv2.lipsiasoft.biz', 'root', :keys => keys

plugin "configure-server", "https://raw.github.com/gist/112..."
```

Then I've some recipes in my `~/.do` path where I do common tasks.

```rb
# ~/.do/configure.
namespace :configure
  desc "upgrade rubygems and install usefull gems"
  task :gems => :ree do
    run "gem update --system" if yes?("Do you want to update rubygems?")
    run "gem install rake"
    run "gem install highline"
    run "gem install bundler"
    run "ln -s /opt/ruby-enterprise/bin/bundle /usr/bin/bundle" unless exist?("/usr/bin/bundle")
  end

  desc "create motd for each server"
  task :motd do
    replace :all, "Hey boss! Welcome to the \e[1m#{name}\e[0m of LipsiaSOFT s.r.l.\n", "/etc/motd"
  end

  desc "redirect emails to a real account"
  task :root_emails do
    append "\nroot: servers@lipsiasoft.com", "/etc/aliases"
    run "newaliases"
  end

  desc "mysql basic configuration"
  task :mysql => :yum do
    run "yum install mysql-server mysql mysql-devel -y"
    run "chkconfig --level 2345 mysqld on"
    run "service mysqld restart"
    pwd = ask "Tell me the password for mysql"
    run "mysqladmin -u root -p password '#{pwd}'", :input => "\n"
    run "service mysqld restart"
    run "ln -fs /var/lib/mysql/mysql.sock /tmp/mysql.sock"
  end
...
```

I call those with:

```sh
$ doit configure:gems
$ doit configure:motd
$ doit configure:mysql
```

**NOTE** that like rake tasks you are be able to add prerequisites to
any task, in this case:

```rb
task :mysql => :yum do; ...; end
```

That's are some local tasks:

```rb
namespace :l do
  local :setup do
    name = File.basename(File.expand_path('.'))
    exit unless yes?('Do you want to setup "%s"?' % name)
    srv = nil

    until servers.map(&:name).include?(srv)
      srv = ask("Which server do you want to use (%s)" % servers.map(&:name).join(", ")).to_sym
    end

    if File.exist?('.git')
      exit unless yes?('Project "%s" has already a working repo, do you want remove it?' % name)
      sh 'rm -rf .git'
    end

    sh 'git init'
    sh 'git remote add origin git@lipsiasoft.biz:/%s.git' % name
    Rake::Task['l:commit'].invoke if yes?("Are you ready to commit it, database, config etc is correct?")
  end

  local :commit do
    sh 'git add .'
    sh 'git commit -a'
    sh 'git push origin master'
  end
end
```

When I need to setup a new project I do:

``` sh
$ doit l:setup
$ doit l:commit # to make a fast commit and push
```

As you can see define remote and local task is simple like making common
rake tasks, infact this gem handle rake.

## Filtering

Sometimes you want to perform a task only on one or some servers:

```sh
$ doit configure:new --only-srv1 --only-srv2
$ doit configure:new --except-srv1
```

## Awesome output

What I really need is a great understandable, colored output that clarify
me what's happen on my remote servers.

```
root@sho0 ~ # touch /root/.bashrc
root@sho0 ~ # replace all in '/root/.bashrc'
root@sho0 ~ # replace all in '/etc/motd'
root@sho0 ~ # replace /HOSTNAME=.*/ in '/etc/sysconfig/network'
root@sho0 ~ # chmod +w /etc/sudoers
root@sho0 ~ # replace /^Defaults    requiretty/ in '/etc/sudoers'
root@sho0 ~ # chkconfig --level 2345 sendmail on
root@sho0 ~ # chkconfig --level 2345 mysqld on
root@sho0 ~ # service sendmail restart
Shutting down sm-client: [  OK  ]
Shutting down sendmail: [  OK  ]
Starting sendmail: [  OK  ]
Starting sm-client: [  OK  ]
root@sho0 ~ # service mysqld restart
Stopping mysqld:  [  OK  ]
Starting mysqld:  [  OK  ]
root@sho0 ~ # Tell me the password for mysql: xx
root@sho0 ~ # mysqladmin -u root -p password xx'
Enter password: xx
mysqladmin: connect to server at 'localhost' failed
error: 'Access denied for user 'root'@'localhost' (using password: NO)'
root@sho0 ~ # service mysqld restart
Stopping mysqld:  [  OK  ]
Starting mysqld:  [  OK  ]
root@sho0 ~ # ln -fs /var/lib/mysql/mysql.sock /tmp/mysql.sock
```

## Copyright

Copyright (C) 2011 Davide D'Agostino -
[@daddye](http://twitter.com/daddye)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and
associated documentation files (the “Software”), to deal in the Software
without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
