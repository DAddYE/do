require 'spec_helper'

describe DO::Parser do

  it 'should parse --foo=bar' do
    parsed = DO::Parser.new('--foo=bar')
    parsed[:foo].should == 'bar'
  end

  it 'should parse -foo=bar' do
    parsed = DO::Parser.new('-foo=bar')
    parsed[:foo].should == 'bar'
  end

  it 'should parse --foo-bar=hey' do
    parsed = DO::Parser.new('--foo-bar=hey')
    parsed[:'foo-bar'].should == 'hey'
  end

  it 'should parse -foo-bar=hey' do
    parsed = DO::Parser.new('-foo-bar=hey')
    parsed[:'foo-bar'].should == 'hey'
  end

  it 'should parse --foo bar' do
    parsed = DO::Parser.new('--foo', 'bar')
    parsed[:foo].should == 'bar'
  end

  it 'should parse -foo bar' do
    parsed = DO::Parser.new('-foo', 'bar')
    parsed[:foo].should == 'bar'
  end

  it 'should parse --foo' do
    parsed = DO::Parser.new('--foo')
    parsed[:foo].should == true
  end

  it 'should parse -foo' do
    parsed = DO::Parser.new('-foo')
    parsed[:foo].should == true
  end

  it 'should parse --no-foo' do
    parsed = DO::Parser.new('--no-foo')
    parsed[:foo].should == false
  end

  it 'should parse -no-foo' do
    parsed = DO::Parser.new('-no-foo')
    parsed[:foo].should == false
  end

  it 'should parse int' do
    parsed = DO::Parser.new('--foo=1')
    parsed[:foo].should == 1
  end

  it 'should parse boolean' do
    parsed = DO::Parser.new('--foo=true')
    parsed[:foo].should == true
    parsed = DO::Parser.new('--foo=false')
    parsed[:foo].should == false
  end

  it 'should parse float' do
    parsed = DO::Parser.new('--foo=100.99')
    parsed[:foo].should == 100.99
  end

  it 'should parse array' do
    parsed = DO::Parser.new('--foo=1,a,b,2')
    parsed[:foo].should == ['1', 'a', 'b', '2']
  end
end
