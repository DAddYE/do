require 'spec_helper'

describe DO::Server do
  before do
    @server = DO::Server.new(:sho0, 'sho0.lipsiasoft.biz', 'ec2-user', :keys => Dir['/Developer/keys/*.pem'])
    @fixture = File.expand_path('../fixtures/sample', __FILE__)
    @fixture_was = File.read(@fixture)
  end

  it 'should read my uname' do
    release = @server.run 'uname'
    release.should match(/Linux/)
  end

  it 'should upload something' do
    @server.upload @fixture, '/tmp/sample'
    @server.exist?('/tmp/sample').should be_true
  end

  it 'should download something' do
    tmp = File.expand_path('./sample')
    @server.download '/tmp/sample', tmp
    File.read(tmp).should == @fixture_was
    FileUtils.rm_rf(tmp)
  end

  it 'should replace in file' do
    @server.replace 'eddies', 'dummies', '/tmp/sample'
    result = @server.read '/tmp/sample'
    result.should match(/dummies/)
  end

  it 'should replace everything' do
    @server.replace :all, 'foo', '/tmp/sample'
    result = @server.read '/tmp/sample'
    result.should == 'foo'
  end

  it 'should not replace if pattern is not valid' do
    proc {
      @server.replace :xyz, 'foo', '/tmp/sample'
    }.should raise_exception
  end

  it 'should replace with a regex' do
    @server.upload @fixture, '/tmp/sample'
    @server.replace /and/, 'AND', '/tmp/sample'
    result  = @server.read '/tmp/sample'
    matches = result.scan(/and/i)
    matches.size.should == 5
    matches.all? { |m| m == 'AND' }.should be_true
  end

  it 'should append on bottom' do
    @server.append '---', '/tmp/sample'
    result = @server.read '/tmp/sample'
    result.should match(/---$/)
    @server.append '~~~', '/tmp/sample', :bottom
    result = @server.read '/tmp/sample'
    result.should match(/~~~$/)
  end

  it 'should append on top' do
    @server.append '---', '/tmp/sample', :top
    result = @server.read '/tmp/sample'
    result.should match(/^---/)
  end

  it 'should not append if the where condition is not valid' do
    proc {
      @server.append 'xyz', '/tmp/sample', :xyz
    }.should raise_exception
  end
end
