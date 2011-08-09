DO_PATH = ENV['DO_PATH'] ||= File.expand_path("~/.do") unless defined?(DO_PATH)

module DO

  autoload :Server,   'do/server.rb'
  autoload :Utils,    'do/utils.rb'
  autoload :VERSION,  'do/version.rb'

  extend self

  ##
  # DO loads rakefiles in these locations:
  #
  #   ~/do/dorc
  #   ~/do/*.rake
  #   ./Do
  #   ./Dofile
  #
  # DO_PATH, default is ~/do.
  #
  def recipes
    @_recipes ||= (
      %w[dorc *.rake].map { |f| Dir[File.join(DO_PATH, f)] }.flatten +
      %w[./Do ./Dofile].map { |f| File.expand_path(f) }
    ).reject { |f| !File.exist?(f) }
  end
end # DO
