#!/usr/bin/env ruby

# to install, add the following line to your .bash_profile or .bashrc
# complete -C ~/.do/completion -o default doit

# Rake completion will return matching rake tasks given typed text. This way
# you can auto-complete tasks as you are typing them by hitting [tab] or [tab][tab]
# This also caches the rake tasks for optimium speed
class DoCompletion
  BIN = File.expand_path('../../bin/doit', __FILE__)

  def initialize(command)
    @command = command
  end

  def matches
    do_tasks.select { |task| task =~ %r[^#{typed}] }.
      map { |task| task.sub(typed_before_colon, '')}
  end

  private
    def typed
      @command[/\s(.+?)$/, 1] || ''
    end

    def typed_before_colon
      typed[/.+\:/] || ''
    end

    def do_tasks
      `#{BIN} list`.split("\n")[1..-1].map { |line| line.split[1] }
    end
end

puts DoCompletion.new(ENV["COMP_LINE"]).matches
exit 0
