module Datagrid
  module Drivers
    class Mongoid < AbstractDriver

      def self.match?(scope)
        if scope.is_a?(Class) 
          scope.ancestors.include?(::Mongoid::Document)
        else
          scope.is_a?(::Mongoid::Criteria)
        end
      end

      def to_scope(scope)
        scope.where
      end

      def where(scope, condition)
        scope.where(condition)
      end

      def asc(scope, order)
        scope.asc(order)
      end

      def desc(scope, order)
        scope.desc(order)
      end

      def default_order(scope, column_name)
        column_name
      end

    end
  end
end
