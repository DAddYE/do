module DO
  module Utils
    ##
    # This is generally used when calling DO::Server from a CLI
    #
    # ==== Examples:
    #   [srv1, srv2, srv3].each do |server|
    #     server.run "long task"
    #     server.wait # because we want to see all outputs before start with new one
    #   end
    #
    def wait
      log "\e[36mPress ENTER to continue...\e[0m"
      $stdin.gets
    end

    ##
    # Ask question to your $stdin.
    # This command is useful in conjunction with a CLI
    #
    # ==== Example
    #   old_pwd = ask "Tell me the old password of mysql"
    #   new_pwd = ask "Tell me the new password of mysql"
    #   run "mysqladmin -u root -p password '#{new_pwd}', :input => old_pwd
    #
    def ask(*args)
      question = args[0]
      options = args.last.is_a?(Hash) ? args.pop : {}
      result = ""
      `stty -echo` if options[:silent]
      loop do
        log("\e[36m%s: \e[0m" % question, false)
        result = $stdin.gets.chomp
        break if options[:allow_blank] || result != ""
      end
      `stty echo` && log("\n", false) if options[:silent]
      result
    end

    ##
    # Ask a yes/no question and return true if it is equal to y or yes
    #
    # ==== Examples:
    #   if yes?("Do you want to proceed?")
    #     do_some
    #   end
    #
    def yes?(question)
      result = ""
      question += "?" if question[-1] != ??
      loop do
        log("\e[36m%s (y/n): \e[0m" % question, false)
        result = $stdin.gets.chomp
        break if result =~ /y|yes|n|no/i
      end
      return result =~ /y|yes/i
    end

    ##
    # Print the text into logger buffer, if you want to change
    # the stream edit the constant DO_LOGGER
    #
    def log(text, new_line=false)
      text += "\n" if new_line && text[-1] != ?\n
      DO_LOGGER.print text
    end
  end # Utils
end # DO
