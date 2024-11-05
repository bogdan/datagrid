# frozen_string_literal: true

module Datagrid
  module Filters
    module RangedFilter
      def initialize(grid, name, options, &block)
        super
        return unless range?

        options[:multiple] = true
      end

      def parse_values(value)
        if value.is_a?(Hash)
          value = parse_hash(value)
        end
        result = super
        return result if !range? || result.nil?
        # Simulate single point range
        return [result, result] unless result.is_a?(Array)

        parse_array(result)
      end

      def range?
        options[:range]
      end

      def default_filter_where(scope, value)
        if range? && value.is_a?(Array)
          left, right = value
          scope = driver.greater_equal(scope, name, left) if left
          scope = driver.less_equal(scope, name, right) if right
          scope
        else
          super
        end
      end

      protected

      def parse_hash(result)
        if result[:from] || result[:to]
          [result[:from], result[:to]]
        else
          nil
        end
      end

      def parse_array(result)
        case result.size
        when 0
          nil
        when 1
          result.first
        when 2
          if result.first && result.last && result.first > result.last
            # If wrong range is given - reverse it to be always valid
            result.reverse
          elsif !result.first && !result.last
            nil
          else
            result
          end
        else
          raise ArgumentError, "Can not create a date range from array of more than two: #{result.inspect}"
        end
      end
    end
  end
end
