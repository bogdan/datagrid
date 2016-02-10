module Datagrid
  module Drivers
    class ActiveRecord < AbstractDriver #:nodoc:

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
          Rails.version >= "4.0" ? scope.all : scope.scoped({})
        elsif scope.respond_to?(:scoped)
          scope.scoped
        else
          scope
        end
      end

      def append_column_queries(assets, columns)
        if columns.present?
          if assets.select_values.empty?
            assets = assets.select(Arel.respond_to?(:star) ? assets.klass.arel_table[Arel.star] : "#{assets.quoted_table_name}.*")
          end
          columns = columns.map {|c| "#{c.query} AS #{c.name}"}
          assets = assets.select(*columns)
        end
        assets
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
        if order.respond_to?(:desc)
          scope.reorder(order.desc)
        else
          scope.reorder(order).reverse_order
        end
      end

      def reverse_order(scope)
        scope.reverse_order
      end

      def default_order(scope, column_name)
        has_column?(scope, column_name) ? prefix_table_name(scope, column_name) : nil
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
        field = prefix_table_name(scope, field)
        scope.where("#{field} #{contains_predicate} ?", "%#{value}%")
      end

      def normalized_column_type(scope, field)
        type = column_type(scope, field)
        return nil unless type
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
      end

      def batch_each(scope, batch_size, &block)
        if scope.limit_value
          raise Datagrid::ConfigurationError, "ActiveRecord can not use batches in combination with SQL limit"
        end
        scope.find_each(batch_size ? { :batch_size => batch_size} : {}, &block)
      end

      def default_cache_key(asset)
        asset.id || raise(NotImplementedError)
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

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.class_eval do
    def self.datagrid_where_by_timestamp(column, value)
      Datagrid::Drivers::ActiveRecord.new.where_by_timestamp_gotcha(self, column, value)
    end
  end
end
