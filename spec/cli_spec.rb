require 'spec_helper'

describe DO::CLI do

  def cli; DO::CLI  end

  it 'should show help if args are empty' do
    DO::CLI.start
    logger.should match(/Usage/)
  end

  it 'should show task list if task does not exist' do
    DO::CLI.start
    logger.should match(/list/)
    logger.should match(/version/)
  end

  it 'should run task' do
    DO::CLI.start(:version)
    logger.should match(DO::VERSION)
  end
end
