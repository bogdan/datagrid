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
        deprecated_key = :"datagrid.#{grid_class.param_name}.#{namespace}.#{key}"
        live_key = :"datagrid.#{grid_class.model_name.i18n_key}.#{namespace}.#{key}"
        i18n_key = grid_class.model_name.i18n_key.to_s

        if grid_class.param_name != i18n_key && I18n.exists?(deprecated_key)
          Datagrid::Utils.warn_once(
            "Deprecated translation namespace 'datagrid.#{grid_class.param_name}' for #{grid_class}. Use 'datagrid.#{i18n_key}' instead."
          )
          return I18n.t(deprecated_key)
        end
        I18n.t(live_key, default: key.to_s.humanize).presence
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

    end
  end
end
