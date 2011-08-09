require 'rake/dsl_definition'
require 'rake'

module DO
  module Commands
    include Rake::DSL
    include DO::Utils

    ##
    # Array of DO::Server defined in our tasks
    #
    def servers
      @_servers ||= []
    end

    ##
    # An array of DO::Server selected by our remote task
    #
    def servers_selected
      @_servers_selected ||=[]
    end

    ##
    # Returns the current server
    #
    def current_server
      @_current_server
    end

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
      local(name) { servers_selected.replace(servers.select { |s| s.name == name }) }
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
      desc "Install #{name} plugin"
      local("plugin:#{name}" => "do:setup") do
        log "\e[36m## Installing plugin %s\e[0m" % name
        Dir.mkdir(DO_PATH) unless File.exist?(DO_PATH)
        sh "curl --location --progress-bar #{repo} > #{File.join(DO_PATH, '%s.rake' % name)}"
      end
    end

    ##
    # Execute DO::Server operations on remote defined servers.
    #
    # ==== Examples:
    #   # Define our ssh connections
    #   keys = %w[key1.pem key2.pem key3.pem key4.pem]
    #   server :srv1, 's1.domain.local', 'user', :keys => keys
    #   server :srv2, 's2.domain.local', 'user', :keys => keys
    #   server :srv3, 's3.domain.local', 'user', :keys => keys
    #   server :srv4, 's4.domain.local', 'user', :keys => keys
    #
    #   # => Executes commands only to :srv1, :srv2, :srv3
    #   remote :name => [:srv1, :srv2, :srv3] do; ...; end
    #
    #   # => Same as above
    #   task :name => [:srv1, :srv2, :srv3] do; ...; end
    #
    #   # => Executes commands on all defined servers
    #   remote :name  => :servers do; ...; end
    #   # => Same as above
    #   remote :name => do; ...; end
    #   # => Same as above
    #   task :name do; ...; end
    #   # => Same as above
    #   local :name => :servers do; ...; end
    #
    #   # => Execute the task on your machine
    #   local :name do; sh 'uname'; end
    #
    #   # => Execute commands both on servers side and local side
    #   remote :name do |t|
    #     t.run 'run this command on remote servers'
    #     sh 'run this command on my local machine'
    #   end
    #
    #   # same of:
    #
    #   task :name do |t|
    #     t.run 'command on remote servers'
    #     sh 'command on my local machine'
    #   end
    #
    #   # => Execute command only on remote server srv1
    #   task :name => :srv1 do
    #     run 'command only on remote server srv1'
    #   end
    #
    def remote(args, &block)
      args = { args => :servers } unless args.is_a?(Hash)
      local(args) do
        name = args.is_a?(Hash) ? args.keys[0] : args
        servers_selected.each do |current|
          begin
            server_was, @_current_server = @_current_server, current
            self.class.send(:define_method, name, &block)
            method = self.class.instance_method(name)
            self.class.send(:remove_method, name)
            block.arity == 1 ? method.bind(self).call(current) : method.bind(current).call
          ensure
            @_current_server = server_was
          end # begin
        end # servers
      end # local
    end

    alias_method :local, :task
    alias_method :task, :remote

    ##
    # Log text under current_server if available
    #
    def log(text="", new_line=true)
      if current_server
        current_server.log(text, new_line)
      else
        text += "\n" if new_line && text[-1] != ?\n
        print(text)
      end
    end
  end # Commands
end # DO

self.extend DO::Commands

load(File.expand_path('../common.rb', __FILE__))
