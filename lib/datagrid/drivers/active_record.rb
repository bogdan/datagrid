module Datagrid
  module Drivers
    class ActiveRecord < AbstractDriver

      def self.match?(scope)
        return false unless defined?(::ActiveRecord)
        if scope.is_a?(Class) 
          scope.ancestors.include?(::ActiveRecord::Base)
        else
          scope.is_a?(::ActiveRecord::Relation) 
        end
      end

      def to_scope(scope)
        scope.scoped({})
      end

      def where(scope, condition)
        scope.where(condition)
      end

      def asc(scope, order)
        # Rails 3.x.x don't able to override already applied order
        # Using #reorder instead
        scope.reorder(order)
      end

      def desc(scope, order)
        scope.reorder(order).reverse_order
      end

      def default_order(scope, column_name)
        scope.column_names.include?(column_name.to_s) ? [scope.table_name, column_name].join(".") : nil
      end

      def greater_equal(scope, field, value)
        scope.where(["#{field} >= ?", value])
      end

      def less_equal(scope, field, value)
        scope.where(["#{field} <= ?", value])
      end
    end
  end
end
