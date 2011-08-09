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
      puts "\e[36mPress ENTER to continue...\e[0m"
      STDIN.gets
    end

    ##
    # Ask question to your STDIN.
    # This command is useful in conjunction with a CLI
    #
    # ==== Example
    #   old_pwd = ask "Tell me the old password of mysql"
    #   new_pwd = ask "Tell me the new password of mysql"
    #   run "mysqladmin -u root -p password '#{new_pwd}', :input => old_pwd
    #
    def ask(question, allow_blank=false)
      result = ""
      loop do
        log("\e[36m%s: \e[0m" % question, false)
        result = STDIN.gets.chomp
        break if allow_blank || result != ""
      end
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
        result = STDIN.gets.chomp
        break if result =~ /y|yes|n|no/i
      end
      return result =~ /y|yes/i
    end
  end # Utils
end # DO
