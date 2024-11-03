# frozen_string_literal: true

module Datagrid
  module Drivers
    # @!visibility private
    class Sequel < AbstractDriver
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

        scope.where({})
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

      def default_order(scope, column_name)
        scope_has_column?(scope, column_name) ? ::Sequel.lit(prefix_table_name(scope, column_name)) : nil
      end

      def greater_equal(scope, field, value)
        scope.where(::Sequel.lit("#{prefix_table_name(scope, field)} >= ?", value))
      end

      def less_equal(scope, field, value)
        scope.where(::Sequel.lit("#{prefix_table_name(scope, field)} <= ?", value))
      end

      def scope_has_column?(scope, column_name)
        scope.columns.include?(column_name.to_sym)
      end

      def column_names(scope)
        scope.columns
      end

      def contains(scope, field, value)
        field = prefix_table_name(scope, field)
        scope.where(Sequel.like(field, "%#{value}%"))
      end

      def normalized_column_type(scope, field)
        type = column_type(scope, field)
        return nil unless type

        {
          %i[string blob time] => :string,
          %i[integer primary_key] => :integer,
          %i[float decimal] => :float,
          [:date] => :date,
          [:datetime] => :timestamp,
          [:boolean] => :boolean
        }.each do |keys, value|
          return value if keys.include?(type)
        end
      end

      def default_cache_key(asset)
        asset.id || raise(NotImplementedError)
      end

      def batch_each(scope, batch_size, &block)
        if scope.opts[:limit]
          scope.each(&block)
        else
          scope.extension(:pagination).each_page(batch_size) do |page|
            page.each(&block)
          end
        end
      end

      def default_preload(scope, value)
        scope.eager(value)
      end

      def can_preload?(scope, association)
        !!scope.model.association_reflection(association)
      end

      protected

      def prefix_table_name(scope, field)
        scope_has_column?(scope, field) ? [to_scope(scope).row_proc.table_name, field].join(".") : field
      end

      def column_type(scope, field)
        scope_has_column?(scope, field) ? to_scope(scope).row_proc.db_schema[field.to_sym][:type] : nil
      end
    end
  end
end
