##
# Common tasks performed by doit
#

local :servers do
  servers_selected.replace(servers)
end

local :download, [:recipe] => 'do:setup'  do |t, options|
  if options[:recipe]
    name = File.basename(options[:recipe], '.rake')
    rc   = File.join(DO_PATH, 'dorc')
    buf  = File.read(rc)

    if buf.include?(options[:recipe])
      log "\e[31mYour '\e[1m%s\e[31m' already has the plugin '\e[1m%s\e[0m'" % [rc, options[:recipe]]
      log "Please run: $ doit plugin:%s" % name
      exit
    else
      plugin = 'plugin :%s, "%s"' % [name, options[:recipe]]
      File.open(rc, 'a') { |f| f.write plugin }
      load(rc)
      Rake::Task['plugin:%s' % name].invoke
    end
  else
    log "\e[31mYou must provide a recipe path ex:\e[0m"
    log
    log "  $ doit download[https://raw.github.com/DAddYE/.do/master/l.rake]"
  end
end

namespace :do do
  desc "setup a working home directory"
  local :setup do
    File.mkdir(DO_PATH) unless File.exist?(DO_PATH)
    hrc = File.expand_path("~/.dorc")
    orc = File.join(DO_PATH, 'dorc')
    unless File.exist?(orc)
      template = <<-RUBY.gsub(/^ {8}/, '')
        ##
        # Server definitions
        #
        # keys = %w(/path/to/key1.pem /path/to/key2.pem)
        # server :srv1, 'srv1.domain.local', 'root', :keys => keys
        # server :srv2, 'srv2.domain.local', 'root', :keys => keys
        #

        ## Here my plugins
        ##
        #
      RUBY
      File.open(orc, 'w') { |f| f.write template }
      log "\e[36mGenerated template, now you can add your config to: '%s'\e[0m" % orc
    end
    sh 'ln -s %s %s' % [orc, hrc] unless File.exist?(hrc)
  end
end
