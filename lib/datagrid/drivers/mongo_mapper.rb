# frozen_string_literal: true

module Datagrid
  module Drivers
    # @!visibility private
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
        scope.sort("#{order} desc")
      end

      def default_order(scope, column_name)
        has_column?(scope, column_name) ? column_name : nil
      end

      def greater_equal(scope, field, value)
        scope.where(field => { "$gte" => value })
      end

      def less_equal(scope, field, value)
        scope.where(field => { "$lte" => value })
      end

      def has_column?(scope, column_name)
        scope.key?(column_name)
      end

      def is_timestamp?(_scope, _column_name)
        # TODO: implement the support
        false
      end

      def contains(_scope, field, value)
        scope(field => Regexp.compile(Regexp.escape(value)))
      end

      def column_names(_scope)
        [] # TODO: implement support
      end

      def batch_each(scope, batch_size, &block)
        current_page = 0
        loop do
          batch = scope.skip(current_page * batch_size).limit(batch_size).to_a
          return if batch.empty?

          scope.skip(current_page * batch_size).limit(batch_size).each(&block)
          current_page += 1
        end
      end

      def default_cache_key(asset)
        raise NotImplementedError
      end

      def default_preload(scope, value)
        raise NotImplementedError
      end

      def can_preload?(_scope, _association)
        false
      end
    end
  end
end
