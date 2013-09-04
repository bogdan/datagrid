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
        return scope if scope.is_a?(::ActiveRecord::Relation)
        # Model class or Active record association
        # ActiveRecord association class hides itself under an Array 
        # We can only reveal it by checking if it respond to some specific
        # to ActiveRecord method like #scoped
        if scope.is_a?(Class) 
          scope.scoped({})
        elsif scope.respond_to?(:scoped)
          scope.scoped
        else
          scope
        end
      end

      def where(scope, attribute, value)
        scope.where(attribute => value)
      end

      def asc(scope, order)
        # Rails 3.x.x don't able to override already applied order
        # Using #reorder instead
        scope.reorder(order)
      end

      def desc(scope, order)
        scope.reorder(order).reverse_order
      end

      # TODO: implement reverse_order
      # def reverse_order(scope)
      #   scope.reverse_order
      # end

      def default_order(scope, column_name)
        has_column?(scope, column_name) ? [scope.table_name, column_name].join(".") : nil
      end

      def greater_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} >= ?", value])
      end

      def less_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} <= ?", value])
      end

      def has_column?(scope, column_name)
        scope.column_names.include?(column_name.to_s)
      rescue ::ActiveRecord::StatementInvalid
        false
      end

      def is_timestamp?(scope, field)
        has_column?(scope, field) && scope.columns_hash[field.to_s].type == :datetime
      end
      
      protected

      def prefix_table_name(scope, field)
        has_column?(scope, field) ?  [scope.table_name, field].join(".") : field
      end
    end
  end
end
