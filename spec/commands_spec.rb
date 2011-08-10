require 'spec_helper'
require 'do/commands.rb'

describe DO::Commands do

  before(:all) { FileUtils.rm_rf(DO_PATH) }
  after(:all)  { FileUtils.rm_rf(DO_PATH) }

  it 'should set DO_PATH' do
    DO_PATH.should == File.expand_path('../tmp', __FILE__)
  end

  it 'should have not an existent DO_PATH' do
    File.exist?(DO_PATH).should be_false
  end

  it 'should have not servers' do
    servers.should be_empty
  end

  it 'should add new servers' do
    server :srv1, 'srv1.domain.local', 'root'
  end

  it 'should create a new remote task' do
    task(:nope) { }
    Rake::Task[:nope].should be_a(Rake::Task)
  end

  it 'should have one server' do
    server :srv1, 'srv1.domain.local', 'root'
    servers.size.should == 1
  end

  it 'should setup a new environment' do
    Rake::Task[:setup].invoke
    File.exist?(File.join(DO_PATH, 'dorc')).should be_true
    logger.should match("Generated template, now you can add your config to:")
  end

   it 'should generate a correct template' do
     dorc = File.read(File.join(DO_PATH, 'dorc'))
     dorc.should match(/# Server definitions/)
     dorc.should match(/# Here my plugins/)
   end

   it 'should add a plugin' do
     recipe = "https://raw.github.com/DAddYE/.do/master/l.rake"
     begin
       stdout_was = STDERR.dup; STDERR.reopen('/dev/null')
       Rake::Task['download'].invoke(recipe)
     ensure
       STDERR.reopen(stdout_was)
     end
     dorc = File.read(File.join(DO_PATH, 'dorc'))
     dorc.should match("plugin :l, '%s'" % recipe)
     dest = File.join(DO_PATH, 'l.rake')
     File.exist?(dest).should be_true
     logger.should match("## Installing plugin l")
   end

   it 'should print unformatted logs' do
     local :sample do
       log 'standard log'
     end
     Rake::Task[:sample].invoke
     logger.should match("standard log")
   end

   it 'should format log if we are in a server' do
     # problem with bind
     local :remote do
       @_current_server = DO::Server.new(:sample, 'host', 'user')
       log 'Im a cmd line'
     end
     Rake::Task[:remote].invoke
     logger.should match(Regexp.escape "\e[36muser\e[33m@\e[31msample \e[33m~ \e[35m#\e[0m Im a cmd line")
   end
end
