# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class DynamicFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      EQUAL_OPERATION = "="
      LIKE_OPERATION = "=~"
      MORE_EQUAL_OPERATION = ">="
      LESS_EQUAL_OPERATION = "<="
      DEFAULT_OPERATIONS = [
        EQUAL_OPERATION,
        LIKE_OPERATION,
        MORE_EQUAL_OPERATION,
        LESS_EQUAL_OPERATION
      ].freeze
      AVAILABLE_OPERATIONS = %w[= =~ >= <=].freeze

      self.default_input_options = {}

      def initialize(*)
        super
        options[:select] ||= default_select
        options[:operations] ||= DEFAULT_OPERATIONS
        return if options.key?(:include_blank)

        options[:include_blank] = false
      end

      def parse_values(filter)
        field, operation, value = filter

        [field, operation, type_cast(field, value)]
      end

      def unapplicable_value?(filter)
        _, _, value = filter
        super(value)
      end

      def default_filter_where(scope, filter)
        field, operation, value = filter
        date_conversion = value.is_a?(Date) && driver.is_timestamp?(scope, field)

        return scope if field.blank? || operation.blank?

        unless operations.include?(operation)
          raise Datagrid::FilteringError,
                "Unknown operation: #{operation.inspect}. Available operations: #{operations.join(' ')}"
        end

        case operation
        when EQUAL_OPERATION
          value = Datagrid::Utils.format_date_as_timestamp(value) if date_conversion
          driver.where(scope, field, value)
        when LIKE_OPERATION
          if column_type(field) == :string
            driver.contains(scope, field, value)
          else
            value = Datagrid::Utils.format_date_as_timestamp(value) if date_conversion
            driver.where(scope, field, value)
          end
        when MORE_EQUAL_OPERATION
          value = value.beginning_of_day if date_conversion
          driver.greater_equal(scope, field, value)
        when LESS_EQUAL_OPERATION
          value = value.end_of_day if date_conversion
          driver.less_equal(scope, field, value)
        else
          raise Datagrid::FilteringError,
                "Unknown operation: #{operation.inspect}. Use filter block argument to implement operation"
        end
      end

      def operations
        options[:operations]
      end

      def operations_select
        operations.map do |operation|
          [I18n.t(operation, scope: "datagrid.filters.dynamic.operations").html_safe, operation]
        end
      end

      protected

      def default_select
        proc { |grid|
          grid.driver.column_names(grid.scope).map do |name|
            # Mongodb/Rails problem:
            # '_id'.humanize returns ''
            [name.gsub(/^_/, "").humanize.strip, name]
          end
        }
      end

      def type_cast(field, value)
        type = column_type(field)
        return nil if value.blank?

        case type
        when :string
          value.to_s
        when :integer
          value.is_a?(Numeric) || value =~ /^\d/ ?  value.to_i : nil
        when :float
          value.is_a?(Numeric) || value =~ /^\d/ ?  value.to_f : nil
        when :date, :timestamp
          Datagrid::Utils.parse_date(value)
        when :boolean
          Datagrid::Utils.booleanize(value)
        when nil
          value
        else
          raise NotImplementedError, "unknown column type: #{type.inspect}"
        end
      end

      def column_type(field)
        grid_class.driver.normalized_column_type(grid_class.scope, field)
      end
    end
  end
end
