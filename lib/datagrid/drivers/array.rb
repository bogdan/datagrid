module Datagrid
  module Drivers
    # @!visibility private
    class Array < AbstractDriver

      def self.match?(scope)
        !Datagrid::Drivers::ActiveRecord.match?(scope) && (
          scope.is_a?(::Array) || scope.is_a?(Enumerator) ||
          (defined?(::ActiveRecord::Result) && scope.is_a?(::ActiveRecord::Result))
        )
      end

      def to_scope(scope)
        scope
      end

      def where(scope, attribute, value)
        scope.select do |object|
          get(object, attribute) == value
        end
      end

      def asc(scope, order)
        return scope unless order
        return scope if order.empty?
        scope.sort_by do |object|
          get(object, order)
        end
      end

      def desc(scope, order)
        asc(scope, order).reverse
      end

      def default_order(scope, column_name)
        column_name
      end

      def reverse_order(scope)
        scope.reverse
      end

      def greater_equal(scope, field, value)
        scope.select do |object|
          get(object, field) >= value
        end
      end

      def less_equal(scope, field, value)
        scope.select do |object|
          get(object, field) <= value
        end
      end

      def has_column?(scope, column_name)
        scope.any? && scope.first.respond_to?(column_name)
      end

      def is_timestamp?(scope, column_name)
        has_column?(scope, column_name) &&
          timestamp_class?(get(scope.first, column_name).class)
      end

      def contains(scope, field, value)
        scope.select do |object|
          get(object, field).to_s.include?(value)
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

      def can_preload?(scope, association)
        false
      end

      protected

      def get(object, property)
        object.is_a?(Hash) ? object[property] : object.public_send(property)
      end
    end
  end
end
