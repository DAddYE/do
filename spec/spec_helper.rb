require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'do'

module Helper
  def capture_stdout(&block)
    stdout_was, $stdout = $stdout, StringIO.new
    block.call
    return $stdout
  ensure
    $stdout = stdout_was
  end
end

RSpec.configure do |config|
  config.include(Helper)
end
