# frozen_string_literal: true

module Datagrid
  module Filters
    module RangedFilter
      SERIALIZED_RANGE = %r{\A(.*)\.{2,3}(.*)\z}

      def parse_values(value)
        return super unless range?

        case value
        when String
          if ["..", "..."].include?(value)
            nil
          elsif (match = value.match(SERIALIZED_RANGE))
            to_range(match.captures[0], match.captures[1], value.include?("..."))
          else
            super
          end
        when Hash
          parse_hash(value)
        when Array
          parse_array(value)
        when Range
          to_range(value.begin, value.end)
        else
          result = super
          to_range(result, result)
        end
      end

      def range?
        options[:range]
      end

      def default_filter_where(scope, value)
        if range? && value.is_a?(Range)
          scope = driver.greater_equal(scope, name, value.begin) if value.begin
          scope = driver.less_equal(scope, name, value.end) if value.end
          scope
        else
          super
        end
      end

      protected

      def parse_hash(result)
        to_range(result[:from], result[:to])
      end

      def to_range(from, to, exclusive = false)
        from = parse(from)
        to = parse(to)
        return nil unless to || from

        # If wrong range is given - reverse it to be always valid
        from, to = to, from if from && to && from > to
        exclusive ? from...to : from..to
      end

      def parse_array(result)
        first = result.first
        last = result.last

        case result.size
        when 0
          nil
        when 1, 2
          to_range(first, last)
        else
          raise ArgumentError, "Can not create a range from array of more than two elements"
        end
      end
    end
  end
end
