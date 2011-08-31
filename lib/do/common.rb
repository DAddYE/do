##
# Common tasks performed by doit
#
desc "download a new recipe with --url="
task :download => :setup  do |options|
  if options[:url]
    name = File.basename(options[:url], '.rake')
    rc   = File.join(DO_PATH, 'dorc')
    buf  = File.read(rc)

    if buf.include?(options[:url])
      log "'\e[1m%s\e[0m' already has plugin '\e[1m%s\e[0m'" % [rc, options[:url]]
      log
      log "Please run: $ doit plugin:%s" % name
      exit
    else
      plugin = "plugin :%s, '%s'\n" % [name, options[:url]]
      File.open(rc, 'a') { |f| f.write plugin }
      load_recipe(rc)
      task_run('plugin:%s' % name)
    end
  else
    log "\e[31mYou must provide a recipe path ex:\e[0m"
    log
    log "  $ doit download --url=https://raw.github.com/DAddYE/.do/master/l.rake"
    log
  end
end

desc "setup a working home directory"
task :setup do |options|
  Dir.mkdir(DO_PATH) unless File.exist?(DO_PATH)
  hrc = File.expand_path("~/.dorc")
  orc = File.join(DO_PATH, 'dorc')
  if File.exist?(orc)
    log "Config already exists in your \e[1m%s\e[0m path." % DO_PATH unless options[:dependency]
  else
    template = <<-RUBY.gsub(/^ {6}/, '')
      ##
      # Server definitions
      #
      # keys = %w(/path/to/key1.pem /path/to/key2.pem)
      # server :srv1, 'srv1.domain.local', 'root', :keys => keys
      # server :srv2, 'srv2.domain.local', 'root', :keys => keys
      #

      ##
      # Here my plugins
      #
    RUBY
    File.open(orc, 'w') { |f| f.write template }
    log "\e[36mGenerated template, now you can add your config to: '%s'\e[0m" % orc
  end
  sh 'ln -s %s %s' % [orc, hrc] unless File.exist?(hrc)
  log "To enable autocompletion add to your \e[1m.bash_profile\e[0m:"
  log "  complete -C %s -o default doit" % File.expand_path('../../../extras/completion.rb', __FILE__)
end

desc "show version number"
task :version do
  log "\e[1mDO\e[0m version %s" % DO::VERSION
end

desc "show task list"
task :list do
  formatted = tasks.map { |t| ["\e[1mdoit\e[0m\e[34m %s:%s \e[0m" % [t[:namespace], t[:name]], t[:desc]] }
  formatted.each { |f| f[0].gsub!(/\s:/, ' ') }
  formatted.reject! { |t, desc| desc == '' }
  max = formatted.max { |a,b| a[0].size <=> b[0].size }[0].size
  log formatted.map { |t, desc| "%s \e[0m# %s" % [t.ljust(max+2), desc] }.join("\n")
end

desc "show help message"
task :help do
  log <<-TEXT.gsub(/^ {4}/, '')
    Usage \e[1mdoit\e[0m task [options]

    Available Tasks:

  TEXT

  run_task(:list)

  log <<-TEXT.gsub(/^ {4}/, '')

    Options:
      Each task can accept multiple options

  TEXT
end
