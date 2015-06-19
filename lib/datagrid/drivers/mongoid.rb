module Datagrid
  module Drivers
    class Mongoid < AbstractDriver #:nodoc:

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
        if value.is_a?(Range)
          value = {"$gte" => value.first, "$lte" => value.last}
        end
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
        column_names(scope).include?(column_name.to_s)
      end

      def is_timestamp?(scope, column_name)
        has_column?(scope, column_name) &&
          timestamp_class?(to_scope(scope).klass.fields[column_name.to_s].type)
      end

      def contains(scope, field, value)
        scope.where(field => Regexp.compile(Regexp.escape(value)))
      end

      def column_names(scope)
        to_scope(scope).klass.fields.keys
      end

      def normalized_column_type(scope, field)
        type = to_scope(scope).klass.fields[field.to_s].try(:type)
        return nil unless type
        {
          [BigDecimal , String, Symbol, Range, Array, Hash, ] => :string,
          [Boolean] => :boolean,

          [Date] => :date,

          TIMESTAMP_CLASSES => :timestamp,

          [Float] => :fload,

          [Integer] => :integer,
        }.each do |keys, value|
          return value if keys.include?(type)
        end
        return :string
      end

      def batch_each(scope, batch_size, &block)
        current_page = 0
        loop do
          batch = scope.skip(current_page * batch_size).limit(batch_size).to_a
          return if batch.empty?
          scope.skip(current_page * batch_size).limit(batch_size).each do |item|
            yield(item)
          end
          current_page+=1
        end
      end

      def default_cache_key(asset)
        asset.id || raise(NotImplementedError)
      end
    end
  end
end

