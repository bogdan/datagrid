module Datagrid
  module Drivers
    class Sequel < AbstractDriver #:nodoc:

      def self.match?(scope)
        return false unless defined?(::Sequel)
        if scope.is_a?(Class)
          scope.ancestors.include?(::Sequel::Model)
        else
          scope.is_a?(::Sequel::Dataset)
        end
      end

      def to_scope(scope)
        return scope if scope.is_a?(::Sequel::Dataset)
        scope.naked
      end

      def asc(scope, order)
        scope.order_append(order)
      end

      def desc(scope, order)
        scope.order_append(::Sequel.desc(order))
      end

      def default_order(scope, column_name)
        nil # has_column?(scope, column_name) ? [scope.table_name, column_name].join(".") : nil
      end
    end
  end
end
