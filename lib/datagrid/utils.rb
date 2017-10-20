module Datagrid
  module Utils # :nodoc:
    class << self


      TRUTH = [true, 1, "1", "true", "yes", "on"]

      def booleanize(value)
        if value.respond_to?(:downcase)
          value = value.downcase
        end
        TRUTH.include?(value)
      end

      def translate_from_namespace(namespace, grid_class, key)

        lookups = []
        namespaced_key = "#{namespace}.#{key}"

        grid_class.ancestors.each do |ancestor|
          if ancestor.respond_to?(:model_name)
            lookups << :"datagrid.#{ancestor.model_name.i18n_key}.#{namespaced_key}"
          end
        end
        lookups << :"datagrid.defaults.#{namespaced_key}"
        lookups << key.to_s.humanize
        I18n.t(lookups.shift, default: lookups).presence
      end

      def warn_once(message, delay = 5)
        @warnings ||= {}
        timestamp = @warnings[message]
        return false if timestamp && timestamp >= Time.now - delay
        warn message
        @warnings[message] = Time.now
        true
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
        before, after = options[:before], options[:after]
        if before && after
          raise Datagrid::ConfigurationError, "Options :before and :after can not be used together"
        end
        # Consider as before all
        return 0 if before == true
        if before
          before = before.to_sym
          array.index {|c| c.name.to_sym == before }
        elsif after
          after = after.to_sym
          array.index {|c| c.name.to_sym == after } + 1
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

      def parse_date(value)
        return nil if value.blank?
        return value if value.is_a?(Range)
        if value.is_a?(String)
          Array(Datagrid.configuration.date_formats).each do |format|
            begin
              return Date.strptime(value, format)
            rescue ::ArgumentError
            end
          end
        end
        return Date.parse(value) if value.is_a?(String)
        return value.to_date if value.respond_to?(:to_date)
        value
      rescue ::ArgumentError
        nil
      end

      def parse_datetime(value)
        return nil if value.blank?
        return value if value.is_a?(Range)
        if value.is_a?(String)
          Array(Datagrid.configuration.datetime_formats).each do |format|
            begin
              return Time.strptime(value, format)
            rescue ::ArgumentError
            end
          end
        end
        return Time.parse(value) if value.is_a?(String)
        return value.to_time if value.respond_to?(:to_time)
        value
      rescue ::ArgumentError
        nil
      end

      def format_date_as_timestamp(value)
        if !value
          value
        elsif value.is_a?(Array)
          [value.first.try(:beginning_of_day), value.last.try(:end_of_day)]
        elsif value.is_a?(Range)
          (value.first.beginning_of_day..value.last.end_of_day)
        else
          value.beginning_of_day..value.end_of_day
        end
      end

      def process_availability(grid, if_option, unless_option)
        property_availability(grid, if_option, true) &&
          !property_availability(grid, unless_option, false)
      end

      def callable(value)
        value.respond_to?(:call) ? value.call : value
      end

      protected
      def property_availability(grid, option, default)
        case option
        when nil
          default
        when Proc
          option.call(grid)
        when Symbol, String
          grid.send(option.to_sym)
        when TrueClass, FalseClass
          option
        else
          raise Datagrid::ConfigurationError, "Incorrect column availability option: #{option.inspect}"
        end
      end
    end
  end
end
