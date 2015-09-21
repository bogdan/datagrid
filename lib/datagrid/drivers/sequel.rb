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
        scope.where
      end

      def append_column_queries(assets, columns)
        super
      end

      def where(scope, attribute, value)
        scope.where(attribute => value)
      end

      def asc(scope, order)
        scope.order(::Sequel.lit(order))
      end

      def desc(scope, order)
        scope.order(::Sequel.desc(::Sequel.lit(order)))
      end

      def reverse_order(scope)
        super
      end

      def default_order(scope, column_name)
        has_column?(scope, column_name) ?  ::Sequel.lit(prefix_table_name(scope, column_name)) : nil
      end

      def greater_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} >= ?", value])
      end

      def less_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} <= ?", value])
      end

      def has_column?(scope, column_name)
        scope.columns.include?(column_name.to_sym)
      end

      def column_names(scope)
        scope.columns
      end

      def is_timestamp?(scope, column_name)
        column_type(scope, column_name) == :datetime
      end

      def contains(scope, field, value)
        field = prefix_table_name(scope, field)
        scope.where(Sequel.like(field, "%#{value}%"))
      end

      def normalized_column_type(scope, field)
        type = column_type(scope, field)
        return nil unless type
        {
          [:string, :blob, :time] => :string,
          [:integer, :primary_key] => :integer,
          [:float, :decimal] => :float,
          [:date] => :date,
          [:datetime] => :datetime,
          [:boolean] => :boolean
        }.each do |keys, value|
          return value if keys.include?(type)
        end
      end

      def default_cache_key(asset)
        asset.id || raise(NotImplementedError)
      end

      def batch_each(scope, batch_size, &block)
        scope.extension(:pagination).each_page(batch_size) do |page|
          page.each(&block)
        end
      end

      protected

      def prefix_table_name(scope, field)
        has_column?(scope, field) ?  [to_scope(scope).row_proc.table_name, field].join(".") : field
      end

      def column_type(scope, field)
        has_column?(scope, field) ? to_scope(scope).row_proc.db_schema[field.to_sym][:type] : nil
      end
    end
  end
end
