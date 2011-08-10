require 'spec_helper'

describe 'DO::Utils' do
  def shell
    @_shell ||= Class.new { include DO::Utils }.new
  end

  it 'should should ask' do
    DO_LOGGER.should_receive(:print).with("\e[36mShould I overwrite it?: \e[0m")
    $stdin.should_receive(:gets).and_return('Sure')
    shell.ask("Should I overwrite it?").should == "Sure"
  end

  it 'should yes? and return true' do
    DO_LOGGER.should_receive(:print).with("\e[36mIt is true? (y/n): \e[0m")
    $stdin.should_receive(:gets).and_return('y')
    shell.yes?('It is true').should be_true
  end

  it 'should yes? and return false' do
    DO_LOGGER.should_receive(:print).with("\e[36mIt is true? (y/n): \e[0m")
    $stdin.should_receive(:gets).and_return('n')
    shell.yes?('It is true').should be_false
  end

  it 'should wait' do
    DO_LOGGER.should_receive(:print).with("\e[36mPress ENTER to continue...\e[0m")
    $stdin.should_receive(:gets).and_return('fooo')
    shell.wait
  end
end
