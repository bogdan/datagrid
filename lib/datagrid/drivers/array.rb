module Datagrid
  module Drivers
    class Array < AbstractDriver #:nodoc:

      def self.match?(scope)
        !Datagrid::Drivers::ActiveRecord.match?(scope) && (scope.is_a?(::Array) || scope.is_a?(Enumerator))
      end

      def to_scope(scope)
        scope
      end

      def where(scope, attribute, value)
        scope.select do |object|
          object.send(attribute) == value
        end
      end

      def asc(scope, order)
        return scope unless order
        return scope if order.empty?
        scope.sort_by do |object|
          object.send(order)
        end
      end

      def desc(scope, order)
        asc(scope, order).reverse
      end

      def default_order(scope, column_name)
        column_name
      end

      def greater_equal(scope, field, value)
        scope.select do |object|
          compare_value = object.send(field)
          compare_value.respond_to?(:>=) && compare_value >= value
        end
      end

      def less_equal(scope, field, value)
        scope.select do |object|
          compare_value = object.send(field)
          compare_value.respond_to?(:<=) && compare_value <= value
        end
      end

      def has_column?(scope, column_name)
        scope.any? && scope.first.respond_to?(column_name)
      end

      def is_timestamp?(scope, column_name)
        has_column?(scope, column_name) &&
          timestamp_class?(scope.first.send(column_name).class)
      end

      def contains(scope, field, value)
        scope.select do |object|
          object.send(field).to_s.include?(value)
        end
      end

      def column_names(scope)
        []
      end

      def batch_each(scope, batch_size, &block)
        scope.each(&block)
      end
      
      def default_cache_key(asset)
        asset
      end
    end
  end
end
