module Datagrid
  module Drivers
    class MongoMapper < AbstractDriver

      def self.match?(scope)
        return false unless defined?(::MongoMapper)
        if scope.is_a?(Class) 
          scope.ancestors.include?(::MongoMapper::Document)
        else
          scope.is_a?(::Plucky::Query)
        end
      end

      def to_scope(scope)
        scope.where
      end

      def where(scope, attribute, value)
        scope.where(attribute => value)
      end

      def asc(scope, order)
        scope.sort(order.asc)
      end

      def desc(scope, order)
        scope.sort(order.desc)
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
        scope.key?(column_name)
      end

      def is_timestamp?(scope, column_name)
        #TODO implement the support
        false
      end
    end
  end
end
