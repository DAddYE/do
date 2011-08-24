# DO .. it! - Framework Toolkit for Sysadmin

DO is a thin framework useful to manage remote servers through ssh.

There are many other alternatives, once of them is
[capistrano](https://github.com/capistrano/capistrano).

So why another one? Basically I need:

* easy creation of my recipes
* see perfectly what's happening on my remote servers
* highly focus on smart actions, upload, download, sudo, replace.
* manage easily more than one server at same time
* a use same syntax to manage local tasks

What really is *DO* ?

* some like brew
* some like rake
* some like capistrano

All togheter mixed to make your life easier.

As mentioned before do is a fun mix of capistrano, rake, thor and brew.

With *DO* you are be able to do easily common task on your local or remote machine.
The aim of *DO* is to become the unique and universal tool language that permit you to make
your own _brew_, _apt-get_ or _yum_ package, same syntax for all your machine.

## DO - Installation and Setup

```sh
$ sudo gem install do
$ doit download # download a new recipe with --url=
$ doit setup    # setup a working home directory
$ doit version  # show version number
$ doit list     # show task list
$ doit help     # show help message
```

Now you can edit your `~/.do/dorc` adding your **servers** or **plugins**.

## DO - Files

There are some way to generate **DO** tasks, you can:

* Create a file called `Do` or `Dofile` in your project directory (_project wide_)
* Create `*.rake` files in `~/.do` directory (_system wide_)
* Create a file called `dorc` in `~/.do` directory (_system wide_)

You can change the *DO* home directory (default: `~/.do`) with these
commands:

```
DO_PATH='/my/new/.do/path'
ENV['DO_PATH']='/my/new/.do/path'
export DO_PATH='/my/new/.do/path'
```

In this guide we assume that your `DO_PATH` is `~/.do`.

## DO - Features

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

server.run 'mysqladmin -u root -p password "oldone"', 'newpassword'
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

## DO - Plugins

DO, support plugins, you can manually add new one in your `~/.do/dorc`
with a simple line:

```rb
plugin :vim, 'https://raw.github.com/DAddYE/.do/master/vim.rake'
```

However we have a `doit` command for that:

```sh
$ doit download --url https://raw.github.com/DAddYE/.do/master/vim.rake
```

This command add for you a new line in your `~/.do/dorc` and perform:

```sh
$ doit plugin:vim
```

which download and install in your `~/.do/dorc` directory a new rake
file.

Once this happen you are be able to see new tasks:

```sh
$ doit list

doit plugin:vim                  # install vim plugin
doit setup                       # setup a working home directory
doit vim:configure               # configure with a janus custom template
doit vim:install                 # install vim with python and ruby support
```

## Scenario and examples

I'm porting my custom recipes to *DO*, you can find my dot files
[here](https://github.com/daddye/.do).

Here servers definitions:

```rb
# ~/.do/dorc
keys = %w(/keys/master.pem /keys/instances.pem /keys/stage.pem)
server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => keys
server :srv0, 'srv0.lipsiasoft.biz', 'root', :keys => keys
server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => keys
server :srv2, 'srv2.lipsiasoft.biz', 'root', :keys => keys
```

I've also some recipes in my `~/.do` path:

```rb
# ~/.do/configure.rake
namespace :configure
  desc "upgrade rubygems and install useful gems"
  task :gems => :ree, :in => :web do
    run "gem update --system" if yes?("Do you want to update rubygems?")
    run "gem install rake"
    run "gem install highline"
    run "gem install bundler"
    run "ln -s /opt/ruby-enterprise/bin/bundle /usr/bin/bundle" unless exist?("/usr/bin/bundle")
  end

  desc "create motd for each server"
  task :motd, :in => :remote do
    replace :all, "Hey boss! Welcome to the \e[1m#{name}\e[0m of LipsiaSOFT s.r.l.\n", "/etc/motd"
  end

  desc "redirect emails to a real account"
  task :root_emails, :in => :remote do
    append "\nroot: servers@lipsiasoft.com", "/etc/aliases"
    run "newaliases"
  end

  desc "mysql basic configuration"
  task :mysql => :yum, :in => :remote do
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

I call these task with:

```sh
$ doit configure:gems
$ doit configure:motd
$ doit configure:mysql
```

**NOTE** like rake tasks you are be able to add prerequisites to
any task, ex:

```rb
task :mysql => :yum, :in => :remote do; ...; end
```

That's are some local tasks:

```rb
namespace :l do
  task :setup do
    name = File.basename(File.expand_path('.'))
    exit unless yes?('Do you want to setup "%s"?' % name)
    srv = nil

    until servers.map(&:name).include?(srv)
      srv = ask("Which server do you want to use (%s)" % servers.map(&:name).join(", ")).to_sym
    end

    if File.exist?('.git')
      exit unless yes?('Project "%s" has already a working repo, do you want remove it?' % name)
      run 'rm -rf .git'
    end

    run 'git init'
    run 'git remote add origin git@lipsiasoft.biz:/%s.git' % name
    run_task('l:commit') if yes?("Are you ready to commit it, database, config etc is correct?")
  end

  task :commit do
    run 'git add .'
    run 'git commit -a'
    run 'git push origin master'
  end
end
```

When I need to setup a new project:

``` sh
$ doit l:setup
$ doit l:commit # to make a fast commit and push
```

As you can see, define remote and local task, is simple like making
standard rake tasks. *DO* extend `Rake`.

## DO - Filtering

Sometimes you want to perform a task only on some servers:

```sh
$ doit configure:new --srv1 # apply recipes only on srv1
$ doit configure:new --no-srv1 # apply recipes to all except srv1
```

## DO - Output (Awesome...)

What I really wanted was a great understandable, colored output that clarify
me what's happen on my remote servers.

Here a example output of my tasks:

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
