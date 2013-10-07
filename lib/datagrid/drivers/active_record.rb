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

      def reverse_order(scope)
        scope.reverse_order
      end

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

      def column_names(scope)
        scope.column_names
      end

      def is_timestamp?(scope, field)
        column_type(scope, field) == :datetime
      end

      def contains(scope, field, value)
        if normalized_column_type(scope, field) == :string
          field = prefix_table_name(scope, field)
          scope.where("#{field} #{contains_predicate} ?", "%#{value}%")
        else
          # dont support contains operation by non-varchar column now
          scope.where("1=0")
        end
      end

      def normalized_column_type(scope, field)
        type = column_type(scope, field)
        {
          [:string, :text, :time, :binary] => :string,
          [:integer, :primary_key] => :integer,
          [:float, :decimal] => :float,
          [:date] => :date,
          [:datetime, :timestamp] => :timestamp,
          [:boolean] => :boolean
        }.each do |keys, value|
          return value if keys.include?(type)
        end
        return :string
      end

      def batch_map(scope, &block)
        result = []
        scope.find_each do |record|
          result << yield(record)
        end
        result
      end
      
      protected

      def prefix_table_name(scope, field)
        has_column?(scope, field) ?  [scope.table_name, field].join(".") : field
      end

      def contains_predicate
        defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) && 
          ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) ? 
          'ilike' : 'like'
      end

      def column_type(scope, field)
        has_column?(scope, field) ? scope.columns_hash[field.to_s].type : nil
      end
    end
  end
end
