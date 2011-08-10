require 'rubygems' unless defined?(Gem)
require 'stringio'

DO_PATH   = File.expand_path('../tmp', __FILE__)
DO_LOGGER = StringIO.new

require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'do'
require 'do/commands'

module Helpers
  def logger
    DO_LOGGER.string
  end
end

RSpec.configure do |c|
  c.include DO::Commands
  c.include Helpers
end
