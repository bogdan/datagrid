# frozen_string_literal: true

module Datagrid
  module Drivers
    # @!visibility private
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
          scope.all
        elsif scope.respond_to?(:scoped)
          scope.scoped
        else
          scope
        end
      end

      def append_column_queries(assets, columns)
        return assets if columns.empty?
        assets = assets.select(assets.klass.arel_table[Arel.star]) if assets.select_values.empty?
        columns = columns.map { |c| "#{c.query} AS #{c.name}" }
        assets.select(*columns)
      end

      def where(scope, attribute, value)
        scope.where(attribute => value)
      end

      def asc(scope, order)
        # Relation#order isn't able to override already applied order
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
        scope_has_column?(scope, column_name) ? prefix_table_name(scope, column_name) : nil
      end

      def greater_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} >= ?", value])
      end

      def less_equal(scope, field, value)
        scope.where(["#{prefix_table_name(scope, field)} <= ?", value])
      end

      def scope_has_column?(scope, column_name)
        scope.column_names.include?(column_name.to_s)
      rescue ::ActiveRecord::StatementInvalid
        false
      end

      def column_names(scope)
        scope.column_names
      end

      def contains(scope, field, value)
        field = prefix_table_name(scope, field)
        scope.where("#{field} #{contains_predicate} ?", "%#{value}%")
      end

      def normalized_column_type(scope, field)
        return nil unless scope_has_column?(scope, field)

        builtin_type = scope.columns_hash[field.to_s].type
        {
          %i[string text time binary] => :string,
          %i[integer primary_key] => :integer,
          %i[float decimal] => :float,
          [:date] => :date,
          %i[datetime timestamp timestamptz] => :timestamp,
          [:boolean] => :boolean,
        }.each do |keys, value|
          return value if keys.include?(builtin_type)
        end
      end

      def batch_each(scope, batch_size, &block)
        if scope.limit_value
          raise Datagrid::ConfigurationError, "ActiveRecord can not use batches in combination with SQL limit"
        end

        options = batch_size ? { batch_size: batch_size } : {}
        scope.find_each(**options, &block)
      end

      def default_cache_key(asset)
        asset.id || raise(NotImplementedError)
      end

      def default_preload(scope, value)
        scope.preload(value)
      end

      def can_preload?(scope, association)
        !!scope.klass.reflect_on_association(association)
      end

      protected

      def prefix_table_name(scope, field)
        scope_has_column?(scope, field) ? [scope.table_name, field].join(".") : field
      end

      def contains_predicate
        if defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) &&
           ::ActiveRecord::Base.connection.is_a?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
          "ilike"
        else
          "like"
        end
      end
    end
  end
end
