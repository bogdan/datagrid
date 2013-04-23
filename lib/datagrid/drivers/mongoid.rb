module Datagrid
  module Drivers
    class Mongoid < AbstractDriver

      def self.match?(scope)
        return false unless defined?(::Mongoid)
        if scope.is_a?(Class) 
          scope.ancestors.include?(::Mongoid::Document)
        else
          scope.is_a?(::Mongoid::Criteria)
        end
      end

      def to_scope(scope)
        scope.where(nil)
      end

      def where(scope, attribute, value)
        scope.where(attribute => value)
      end

      def asc(scope, order)
        scope.asc(order)
      end

      def desc(scope, order)
        scope.desc(order)
      end

      def default_order(scope, column_name)
        has_column?(scope, column_name) ? column_name : nil
      end

      def greater_equal(scope, field, value)
        scope.where(field => {"$gte" => value})
      end

      def less_equal(scope, field, value)
        scope.where(field => {"$lte" => value})
      end

      def has_column?(scope, column_name)
        to_scope(scope).klass.fields.keys.include?(column_name.to_s)
      end
    end
  end
end
