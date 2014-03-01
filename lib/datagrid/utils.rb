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
              return DateTime.strptime(value, format)
            rescue ::ArgumentError
            end
          end
        end
        return DateTime.parse(value) if value.is_a?(String)
        return value.to_datetime if value.respond_to?(:to_datetime)
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
