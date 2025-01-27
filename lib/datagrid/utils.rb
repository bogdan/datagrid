# frozen_string_literal: true

module Datagrid
  # @!visibility private
  module Utils
    class << self
      TRUTH = [true, 1, "1", "true", "yes", "on"].freeze

      def booleanize(value)
        value = value.downcase if value.respond_to?(:downcase)
        TRUTH.include?(value)
      end

      def translate_from_namespace(namespace, grid_class, key)
        lookups = []
        namespaced_key = "#{namespace}.#{key}"

        grid_class.ancestors.each do |ancestor|
          lookups << :"datagrid.#{ancestor.model_name.i18n_key}.#{namespaced_key}" if ancestor.respond_to?(:model_name)
        end
        lookups << :"datagrid.defaults.#{namespaced_key}"
        lookups << key.to_s.humanize
        I18n.t(lookups.shift, default: lookups).presence
      end

      def deprecator
        if defined?(Rails) && Rails.version >= "7.1.0"
          Rails.deprecator
        else
          ActiveSupport::Deprecation
        end
      end

      def warn_once(message, delay = 5)
        @warnings ||= {}
        timestamp = @warnings[message]
        return false if timestamp && timestamp >= Time.now - delay

        deprecator.warn(message)
        @warnings[message] = Time.now
        true
      end

      def add_html_classes(options, *classes)
        return options if classes.empty?

        options = options.clone
        options[:class] ||= []
        array = options[:class].is_a?(Array)
        value = [*options[:class], *classes]
        options[:class] = array ? value : value.join(" ")
        options
      end

      def string_like?(value)
        value.is_a?(Symbol) || value.is_a?(String)
      end

      def extract_position_from_options(array, options)
        before = options[:before]
        after = options[:after]
        raise Datagrid::ConfigurationError, "Options :before and :after can not be used together" if before && after
        # Consider as before all
        return 0 if before == true

        if before
          before = before.to_sym
          array.index { |c| c.name.to_sym == before }
        elsif after
          after = after.to_sym
          array.index { |c| c.name.to_sym == after } + 1
        else
          -1
        end
      end

      def apply_args(*args, &block)
        size = block.arity.negative? ? args.size : block.arity
        block.call(*args.slice(0, size))
      end

      def parse_date(value)
        return nil if value.blank?
        return value if value.is_a?(Range)

        if value.is_a?(String)
          Array(Datagrid.configuration.date_formats).each do |format|
            return Date.strptime(value, format)
          rescue ::ArgumentError
            nil
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
        return value if defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone)

        if value.is_a?(String)
          Array(Datagrid.configuration.datetime_formats).each do |format|
            return Time.strptime(value, format)
          rescue ::ArgumentError
            nil
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
        elsif value.is_a?(Range)
          value.begin&.beginning_of_day..value.end&.end_of_day
        else
          value.beginning_of_day..value.end_of_day
        end
      end

      def process_availability(grid, if_option, unless_option)
        property_availability(grid, if_option, true) &&
          !property_availability(grid, unless_option, false)
      end

      def callable(value, *arguments)
        value.respond_to?(:call) ? value.call(*arguments) : value
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
