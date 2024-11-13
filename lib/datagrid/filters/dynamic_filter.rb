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
        LESS_EQUAL_OPERATION,
      ].freeze
      AVAILABLE_OPERATIONS = %w[= =~ >= <=].freeze

      def initialize(grid, name, **options, &block)
        options[:select] ||= default_select
        options[:operations] ||= DEFAULT_OPERATIONS
        options[:include_blank] = false unless options.key?(:include_blank)
        super
      end

      def default_input_options
        { **super, type: nil }
      end

      def parse_values(filter)
        filter ? FilterValue.new(grid_class, filter) : nil
      end

      def unapplicable_value?(filter)
        super(filter&.value)
      end

      def default_filter_where(scope, filter)
        field = filter.field
        operation = filter.operation
        value = filter.value
        date_conversion = value.is_a?(Date) && driver.timestamp_column?(scope, field)

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
          [I18n.t(operation, scope: "datagrid.filters.dynamic.operations"), operation]
        end
      end

      protected

      def default_select
        proc { |grid|
          grid.driver.column_names(grid.scope).map do |name|
            # Mongodb/Rails problem:
            # '_id'.humanize returns ''
            [name.gsub(%r{^_}, "").humanize.strip, name]
          end
        }
      end

      def column_type(field)
        grid_class.driver.normalized_column_type(grid_class.scope, field)
      end

      class FilterValue
        attr_accessor :field, :operation, :value

        def initialize(grid_class, object = nil)
          super()

          case object
          when Hash
            object = object.symbolize_keys
            self.field = object[:field]
            self.operation = object[:operation]
            self.value = object[:value]
          when Array
            self.field = object[0]
            self.operation = object[1]
            self.value = object[2]
          else
            raise ArgumentError, object.inspect
          end
          return unless grid_class

          type = grid_class.driver.normalized_column_type(
            grid_class.scope, field,
          )
          self.value = type_cast(type, value)
        end

        def inspect
          { field: field, operation: operation, value: value }
        end

        def to_ary
          to_a
        end

        def to_a
          [field, operation, value]
        end

        def to_h
          { field: field, operation: operation, value: value }
        end

        protected

        def type_cast(type, value)
          return nil if value.blank?

          case type
          when :string
            value.to_s
          when :integer
            value.is_a?(Numeric) || value =~ %r{^\d} ?  value.to_i : nil
          when :float
            value.is_a?(Numeric) || value =~ %r{^\d} ?  value.to_f : nil
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
      end
    end
  end
end
