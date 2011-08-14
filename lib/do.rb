DO_PATH = ENV['DO_PATH'] ||= File.expand_path("~/.do") unless defined?(DO_PATH)
DO_LOGGER = $stdout unless defined?(DO_LOGGER)
DO_LOGGER_FORMAT = "\e[36m%s\e[33m@\e[31m%s \e[33m~ \e[35m#\e[0m %s" unless defined?(DO_LOGGER_FORMAT)

module DO
  autoload :CLI,      'do/cli.rb'
  autoload :Server,   'do/server.rb'
  autoload :Utils,    'do/utils.rb'
  autoload :Commands, 'do/commands.rb'
  autoload :Tasks,    'do/tasks.rb'
  autoload :Parser,   'do/parser.rb'
  autoload :VERSION,  'do/version.rb'
end # DO
