require 'net/ssh'
require 'net/sftp'

module DO
  class Server
    include DO::Utils

    attr_reader :name, :host, :user, :role, :options
    # Configuration
    attr_accessor :request_pty, :hidden, :silent

    ##
    # Initialize a new DO Server
    #
    # name:: is a shortcut useful in rake tasks
    # host:: is the host where we connect
    # user:: the user of our server
    # options:: an hash of options used by ssh/sftpd, where normally we provide :keys => ['path/to/key.pem']
    #
    # ==== Examples:
    #   srv1 = DO::Server.new(:srv1, 'srv1.lipsiasoft.biz', 'root', :keys => %w[/path/to/key.pem]
    #
    def initialize(name, host, user, options={})
      @name, @host, @user, @role, @options = name, host, user, options.delete(:role), options
      @request_pty, @hidden, @silence = true, false, false
    end

    ##
    # Method used to print a formatted version of our commands
    # using DO::Server::DO_LOGGER_FORMAT, by default we have a nice
    # colored version like:
    #
    #   srv1@root ~ # ls -al
    #
    # If you don't like colors or our format feel free to edit:
    #
    # ==== Examples:
    #   DO::Server::DO_LOGGER_FORMAT = "%s@%s$ %s"
    #
    def log(text="", new_line=true)
      super(DO_LOGGER_FORMAT % [user, name, text], new_line)
    end

    ##
    # This is the ssh connection
    #
    def ssh
      @_ssh ||= Net::SSH.start(host, user, options)
    end

    ##
    # The sftp connection used to perform uploads, downloads
    #
    def sftp
      @_sftp ||= Net::SFTP.start(host, user, options)
    end

    ##
    # Method used to close the ssh connection
    #
    def close
      ssh.close if @_ssh
    end

    ##
    # Run commands on remote server
    #
    # ==== Examples:
    #   run 'ls -al'
    #   run 'ls', '-al'
    #   run do |cmd|
    #     cmd << 'cd /mnt/www/apps'
    #     cmd << 'tar zxcf /tmp/backup.tar.gz project'
    #   end
    #   run 'mysqladmin -u root -p password 'new', :input => 'oldpassword'
    #
    def run(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      { :sep => " "}.merge(options)

      # If we give a block we run commands one by one
      if block_given?
        options.merge!(:sep => " && ")
        yield args
      end

      # Set default options if not given
      options[:pty]    = request_pty unless options.has_key?(:pty)
      options[:hidden] = hidden      unless options.has_key?(:hidden)
      options[:silent] = silent      unless options.has_key?(:silent)

      cmd = args.join(options[:sep] || ' ')
      if options[:as]
        if options[:as] == 'root'
          cmd = "sudo #{cmd}"
        else
          cmd = "su #{options[:as]} -c '#{cmd.gsub("'", "'\\\\''")}'"
        end
      end
      log(cmd) unless options[:hidden]
      result = ""
      ssh.open_channel do |channel|
        channel.request_pty if options[:input] || options[:pty]
        channel.exec cmd
        channel.on_data do |c, data|
          result << data
          unless options[:silent] || options[:hidden]
            DO_LOGGER.print(data); DO_LOGGER.flush
          end
          if options[:input]
            match = options[:match] || /password/i
            if data =~ match
              options[:input] += "\n" if options[:input][-1] != ?\n
              channel.send_data(options[:input])
              DO_LOGGER.puts(options[:input]) unless options[:silent] || options[:hidden] || data =~ /password/i
            end
          end
        end
      end
      ssh.loop
      result.chomp
    end

    ##
    # Returns true if a given file exist on the remote server
    #
    def exist?(file, options={})
      options = { :hidden => true }.merge(options)
      run("test -e #{file} && echo True", options) == "True"
    end

    ##
    # Return the content of a given file
    #
    def cat(file, options={})
      options = { :hidden => true }.merge(options)
      run("cat #{file}", options)
    end

    ##
    # Upload a file or directory from a local location to the remote location
    # When you need to upload a directory you need to provide:
    #
    #   :recursive => true
    #
    # === Examples
    #   upload(/my/file, /tmp/file)
    #   up(/my/dir, /tmp, :recursive => true)
    #
    def upload(from, to, options={})
      sftp.upload!(from, to, options) do |event, uploader, *args|
        case event
        when :put
          DO_LOGGER.print("\r" + DO_LOGGER_FORMAT % [user, name, "writing: #{to} (#{(args[1].to_f * 100 / args[0].size.to_f).to_i}%)"]); DO_LOGGER.flush
        when :finish
          DO_LOGGER.puts("\r" + DO_LOGGER_FORMAT % [user, name, "writing: #{to} (100%)"]); DO_LOGGER.flush
        # when :mkdir
        #   log "creating directory #{args[0]}"
        end
      end
    end
    alias :up :upload

    ##
    # Download a file o a directory from a remote location to a local location
    # As for +upload+ we can download an entire directory providing
    #
    #   :recursive => true
    #
    # ==== Examples
    #   download(/tmp/file, /my/file)
    #   get(/tmp/dir, /my, :recursive => true)
    #
    def download(from, to, options={})
      sftp.download!(from, to, options) do |event, downloader, *args|
        case event
        when :get
          size = args[0].size ? args[0].size : sftp.stat!(from).size
          DO_LOGGER.print("\r" + DO_LOGGER_FORMAT % [user, name, "sending: #{from} (#{(args[1].to_f * 100 / size.to_f).to_i}%)"]); DO_LOGGER.flush
        when :finish
          DO_LOGGER.puts("\r" + DO_LOGGER_FORMAT % [user, name, "sending: #{from} (100%)"]); DO_LOGGER.flush
        # when :mkdir
        #   log "creating directory #{args[0]}"
        end
      end
    end
    alias :get :download

    ##
    # Replace a pattern with text in a given file.
    #
    # Pattern can be:
    #
    # * string
    # * regexp
    # * symbol (:all, :any, :everything) => replace all content
    #
    # ==== Examples
    #   replace :all, my_template, "/root/.gemrc"
    #   replace /^motd/, "New motd", "/etc/motd"
    #   replace "Old motd, "New motd", "/etc/motd"
    #
    def replace(pattern, replacement, file)
      was = sftp.file.open(file, "r") { |f| f.read }
      found = case pattern
        when :all, :any, :everything
          log "replace \e[1m%s\e[0m in '%s'" % [pattern, file]
          true
        when Regexp
          log "replace \e[1m%s\e[0m in '%s'" % [pattern.inspect, file]
          replacement = was.gsub(pattern, replacement)
          was =~ pattern
        when String
          log "replace \e[1m%s\e[0m in '%s'" % ["String", file]
          replacement = was.gsub(pattern, replacement)
          was.include?(pattern)
        else raise "%s is not a valid. You can use a String, Regexp or :all, :any and :everything" % pattern.inspect
      end

      if found
        sftp.file.open(file, "w") { |f| f.write replacement }
      else
        log "\e[31m '%s' does not include your \e[1mpattern\e[0m" % file unless was =~ pattern
      end
    end
    alias :gsub :replace

    def create_file(text, file)
      sftp.file.open(file, 'w') { |f| f.write text }
      log 'written %s' % file
    end

    ##
    # Append text into a given file in a specified location
    #
    # Locations can be:
    #
    # :top, :start:: Add your text before the old content
    # :bottom, :end:: Append your text at bottom of your file
    #
    # ==== Examples:
    #   append "By default Im at bottom", "/tmp/file"
    #   append "Im on top", "/tmp/file", :top
    #
    def append(pattern, file, where=:bottom)
      was = sftp.file.open(file, "r") { |f| f.read }

      if was.include?(pattern)
        log "'%s' already match your pattern" % file
        return false
      else
        pattern += "\n" unless pattern[-1] == ?\n
        replacement = case where
          when :top, :start  then pattern+was
          when :bottom, :end then was+pattern
          else raise "%s is not a valid, available values are (:top, :start, :bottom, :end)" % where.inspect
        end
      end

      log "append to '%s' in '%s'" % [where, file]
      sftp.file.open(file, "w") { |f| f.write(replacement) }
    end
  end # Server
end # DO
