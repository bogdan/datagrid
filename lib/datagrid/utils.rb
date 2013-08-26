module Datagrid
  module Utils
    class << self


      TRUTH = [true, 1, "1", "true", "yes", "on"]

      def booleanize(value)
        TRUTH.include?(value)
      end

      def warn_once(message)
        @warnings ||= {}
        if @warnings[message] 
          false
        else
          warn message
          @warnings[message] = true
        end
      end

      def add_html_classes(options, *classes)
        options = options.clone
        options[:class] ||= ""
        if options[:class].is_a?(Array)
          options[:class] += classes
        else
          # suppose that it is a String
          options[:class] += " " unless options[:class].blank?
          options[:class] += classes.join(" ")
        end
        options
      end

      def string_like?(value)
        value.is_a?(Symbol) || value.is_a?(String)
      end

      def extract_position_from_options(array, options)
        position = options.extract!(:before, :after)
        if position[:before]
          array.index {|c| c.name.to_sym == position[:before].to_sym }
        elsif position[:after]
          array.index {|c| c.name.to_sym == position[:after].to_sym } + 1
        else
          -1
        end
      end

      def apply_args(*args, &block)
        return block.call(*args) if block.arity < 0
        args = args.clone
        (args.size - block.arity).times do
          args.pop
        end
        block.call(*args)
      end
    end
  end
end
