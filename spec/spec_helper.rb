require 'rubygems' unless defined?(Gem)
require 'stringio'

DO_PATH   = File.expand_path('../tmp', __FILE__)
DO_LOGGER = StringIO.new

require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'do'

module Helpers
  def logger
    DO_LOGGER.string
  end
end

RSpec.configure do |c|
  c.include Helpers
end
