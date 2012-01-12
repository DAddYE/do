module DO
  module Tasks
    class NotFound < StandardError; end
    extend self

    def tasks
      @_tasks ||= []
    end

    def desc(*args)
      @_desc = args.shift
    end

    def namespace(text, &block)
      namespace_was, @_namespace = @_namespace, text.to_s
      @_namespace = '%s:%s' % [namespace_was, @_namespace] if namespace_was && namespace_was != ''
      block.call
    ensure
      @_namespace = namespace_was
    end

    def task(name, options={},  &block)
      name, deps, options = *case name
        when Hash
          in_was = name.delete(:in)
          name_and_deps = name.shift
          name.merge!(:in => in_was) if in_was
          name_and_deps.push(name)
        else [name, [], options]
      end
      tasks.push(options.merge({
        :name      => name.to_s,
        :desc      => @_desc.to_s,
        :deps      => Array(deps),
        :namespace => @_namespace.to_s,
        :block     => block,
        :in        => Array(options[:in] ? options[:in] : options[:on])
      }))
      tasks[-1]
    ensure
      @_desc = nil
    end

    def task_run(*args)
      args_was = args.dup
      task = task_find(args.shift)
      opts = DO::Parser.new(*args)
      task[:deps].each do |dep|
        name = dep.is_a?(Symbol) && task[:namespace] != '' ? '%s:%s' % [task[:namespace], dep] : dep
        task_run(*args.unshift(name).push('--dependency'))
      end
      if task[:in].empty?
        task[:block].arity == 1 ? task[:block].call(opts) : task[:block].call if task[:block]
      else
        task[:in] = send(task[:in][0]) if task[:in].size == 1 && singleton_class.method_defined?(task[:in][0])
        Array(task[:in]).each do |d|
          d = d.is_a?(DO::Server) ? d.name : d
          parent = task_find(d)
          case parent[:block].arity
            when 1 then parent[:block].call(task[:block])
            when 2 then parent[:block].call(opts, task[:block])
            else parent[:block].call
          end
        end
      end
    rescue NotFound => e
      singleton_class.method_defined?(args_was[0]) ? send(args_was.shift) : raise(e)
    end
    alias :run_task :task_run

    def task_find(name)
      spaces = name.to_s.split(":")
      task   = spaces.pop
      tasks.find { |t| t[:name] == task && t[:namespace] == spaces.join(":") } || raise(NotFound, 'Task with "%s" not found' % name)
    end
  end # Tasks
end # DO
