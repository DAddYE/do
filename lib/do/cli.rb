module DO
  module CLI
    extend self

    def start(*args)
      DO::Commands.load_recipes
      args.empty? ? DO::Commands.run_task(:help) : DO::Commands.task_run(*args)
    rescue DO::Tasks::NotFound
      puts "\e[31mSorry, \e[1m'%s'\e[0m\e[31m was not found, see available tasks:\e[0m" % args.join(' ')
      puts
      DO::Commands.run_task(:list)
    end
  end # CLI
end # DO
