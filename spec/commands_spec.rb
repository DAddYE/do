require 'spec_helper'
require 'do/commands.rb'

class Faker
  extend DO::Commands

  load_recipes

  task :sample do
    puts "I'm a fantastic sample"
  end

  def demos
    @a=1
  end
end

describe DO::Commands do

  def cmd; DO::Commands; end

  before(:each){ cmd.tasks.clear; cmd.load_recipes; cmd.servers.clear }
  before(:all) { FileUtils.rm_rf(DO_PATH) }
  after(:all)  { FileUtils.rm_rf(DO_PATH) }

  it 'should set DO_PATH' do
    DO_PATH.should == File.expand_path('../tmp', __FILE__)
  end

  it 'should have not an existent DO_PATH' do
    File.exist?(DO_PATH).should be_false
  end

  it 'should have common tasks' do
    Faker.tasks.size.should == 6
  end

  it 'should have not servers' do
    cmd.servers.should be_empty
    Faker.servers.should be_empty
  end

  it 'should create a new task' do
    tasks_was = cmd.tasks.size
    cmd.task(:nope) { }
    cmd.tasks.size.should == tasks_was+1
  end

  it 'should have one server' do
    cmd.server :srv1, 'srv1.domain.local', 'root'
    cmd.servers.size.should == 1
    Faker.servers.should be_empty
  end

  it 'should setup a new environment' do
    cmd.task_run(:setup)
    File.exist?(File.join(DO_PATH, 'dorc')).should be_true
    logger.should match("Generated template, now you can add your config to:")
  end

  it 'should generate a correct template' do
    dorc = File.read(File.join(DO_PATH, 'dorc'))
    dorc.should match(/# Server definitions/)
    dorc.should match(/# Here my plugins/)
  end

  it 'should add a plugin' do
    recipe = "https://raw.github.com/gist/1143314/4e1c504e4dfbd988c76e6e28a445d985df2644d0/sample.rake"
    begin
      stdout_was = STDERR.dup; STDERR.reopen('/dev/null')
      cmd.task_run(:download, '--url=%s' % recipe)
      expect { Faker.task_run(:download, '--url=%s' % recipe) }.to raise_error(SystemExit)
    ensure
      STDERR.reopen(stdout_was)
    end
    logger.should match(/already has plugin/)
    dorc = File.read(File.join(DO_PATH, 'dorc'))
    dorc.should match("plugin :sample, '%s'" % recipe)
    dest = File.join(DO_PATH, 'sample.rake')
    File.exist?(dest).should be_true
    logger.should match("## Installing plugin sample")
    cmd.run_task('sample')
    logger.should match("Hey")
  end

  it 'should print unformatted logs' do
    cmd.task :sample do
      cmd.log 'standard log'
    end
    cmd.task_run :sample
    logger.should match("standard log")
  end

  it 'should set correclty an option to the given value' do
    cmd.set :foo, :bar
    cmd.foo.should == :bar
  end

  it 'should show version number' do
    cmd.run_task(:version)
    logger.should match(DO::VERSION)
  end

  it 'should show help' do
    cmd.run_task(:help)
    logger.should match(/Usage/)
  end

  context DO::Server do

    it 'should create a basic server' do
      cmd.server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.task :test, :in => :sho0 do
        cmd.run('uname').should == 'Linux'
      end
      cmd.task_run(:test)
    end

    it 'should connect to two servers' do
      cmd.server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.task :connection, :in => [:srv1, :sho0] do
        cmd.run('uname -a').should match(cmd.current_server.name.to_s)
      end
      cmd.task_run(:connection)
      cmd.current_server.should be_nil
    end

    it 'should works with complex tasks' do
      cmd.server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.task :connection, :in => :remote do
        cmd.run('uname -a').should match(cmd.current_server.name.to_s)
      end
      cmd.task_run(:connection)
      cmd.current_server.should be_nil
    end

    it 'should skip if --no-xx' do
      cmd.server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.task :hostname, :in => :remote do |options|
        cmd.run('hostname').should match(/srv1/)
      end
      cmd.task_run(:hostname, '--no-sho0')
    end

    it 'should match one if --xx' do
      cmd.server :sho0, 'sho0.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.server :srv1, 'srv1.lipsiasoft.biz', 'root', :keys => Dir['/Developer/keys/*.pem']
      cmd.task :hostname, :in => :remote do |options|
        cmd.run('hostname').should match(/srv1/)
      end
      cmd.task_run(:hostname, '--srv1')
    end
  end # DO::Server
end # DO::Commands
