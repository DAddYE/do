module DO
  module Commands
    include DO::Tasks
    include DO::Utils

    extend self

    ##
    # Array of DO::Server defined in our tasks
    #
    def servers
      @_servers ||= []
    end

    def remote
      servers.map(&:name)
    end

    ##
    # Returns the current server
    #
    def current_server
      @_current_server
    end

    ##
    # Set an option to the given value
    #
    def set(option, value)
      define_method(option) { value }
    end

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
        %w[dorc **/*.rake].map { |f| Dir[File.join(DO_PATH, f)] }.flatten +
        %w[./Do ./Dofile].map { |f| File.expand_path(f) } <<
        File.expand_path('../common.rb', __FILE__)
      ).reject { |f| !File.exist?(f) }
    end

    def load_recipes
      recipes.each { |f| load_recipe(f) }
    end

    def load_recipe(path)
      instance_eval(File.read(path), __FILE__, __LINE__)
    end
    alias :load :load_recipe

    ##
    # This method define our servers
    #
    # ==== Examples:
    #   keys = %w[key1.pem key2.pem key3.pem key4.pem]
    #   server :srv1, 's1.domain.local', 'user', :keys => keys
    #   server :srv2, 's2.domain.local', 'user', :keys => keys
    #   server :srv3, 's3.domain.local', 'user', :keys => keys
    #   server :srv4, 's4.domain.local', 'user', :keys => keys
    #
    def server(name, host, user, options={})
      servers.push(DO::Server.new(name, host, user, options))
      task name do |opts, b|
        allowed  = opts.map { |k,v| k if remote.include?(k) && v }.compact
        denied   = opts.map { |k,v| k if remote.include?(k) && v == false }.compact
        if (allowed.empty? && denied.empty?) ||
           (!allowed.empty? && allowed.include?(name)) ||
           (!denied.empty? && !denied.include?(name))
          @_current_server = servers.find { |s| s.name == name }
          begin
            b.arity == 1 ? b.call(opts) : b.call
          ensure
            @_current_server = nil
          end
        end
      end
    end

    ##
    # Install in your DO_PATH a remote task
    #
    # === Examples
    #   # You can install/update task with
    #   # rake plugin:configuration
    #   plugin "configuration", "https://gist.github.com/raw/xys.rake"
    #
    def plugin(name, repo)
      desc "install #{name} plugin"
      namespace :plugin do
        task(name => 'setup') do
          log "\e[36m## Installing plugin %s\e[0m" % name
          Dir.mkdir(DO_PATH) unless File.exist?(DO_PATH)
          path = File.join(DO_PATH, '%s.rake' % name)
          sh :curl, '--location', '--progress-bar', repo, '>', path
          load_recipe(path)
        end
      end
    end

    ##
    # Log text under current_server if available
    #
    def log(text="", new_line=true)
      current_server ? current_server.log(text, new_line) : super(text, new_line)
    end

    ##
    # Run commands on current_server if available
    #
    def run(*args)
      current_server ? current_server.run(*args) : super(*args)
    end

    def method_missing(method, *args,  &block)
      current_server && current_server.respond_to?(method) ? current_server.send(method, *args) : super(method, *args,  &block)
    end
  end # Commands
end # DO
