module DO
  class Parser < Hash

    def initialize(*args)
      options = {}
      args.each_with_index do |arg, i|
        case arg
          # --foo=bar
          when /=/
            key, value = *arg.split("=")
            options[key.sub(/^-{1,2}/,'').to_sym] = value
          # --no-foo
          when /^-{1,2}no-(.+)/
            options[$1.to_sym] = false
          # --foo bar
          # --foo
          # -foo
          when /^-{1,2}(.+)/
            key = $1.to_sym
            value = args[i+1] && args[i+1] !~ /^-{1,2}/ ? args.delete_at(i+1) : true
            options[key] = value
        end
      end

      # Automatically map values
      options.each do |k, v|
        case v
          when /^true$/i   then options[k] = true
          when /^false$/i  then options[k] = false
          when /^\d+$/     then options[k] = v.to_i
          when /^[\d\.]+$/ then options[k] = v.to_f
          when /,/         then options[k] = v.split(",")
        end
      end

      self.replace(options)
    end
  end # Parser
end # DO
