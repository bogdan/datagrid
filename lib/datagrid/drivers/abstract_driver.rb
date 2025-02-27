# frozen_string_literal: true

module Datagrid
  module Drivers
    # @!visibility private
    class AbstractDriver
      TIMESTAMP_CLASSES = [DateTime, Time, ActiveSupport::TimeWithZone].freeze

      class_attribute :subclasses, default: []

      def self.inherited(base)
        super
        subclasses << base
      end

      def self.guess_driver(scope)
        subclasses.find do |driver_class|
          driver_class.match?(scope)
        end || raise(Datagrid::ConfigurationError, "ORM Driver not found for scope: #{scope.inspect}.")
      end

      def self.match?(scope)
        raise NotImplementedError
      end

      def match?(scope)
        self.class.match?(scope)
      end

      def to_scope(scope)
        raise NotImplementedError
      end

      def where(scope, attribute, value)
        raise NotImplementedError
      end

      def asc(scope, order)
        raise NotImplementedError
      end

      def desc(scope, order)
        raise NotImplementedError
      end

      def default_order(scope, column_name)
        raise NotImplementedError
      end

      def greater_equal(scope, field, value)
        raise NotImplementedError
      end

      def less_equal(scope, field, value)
        raise NotImplementedError
      end

      def scope_has_column?(scope, column_name)
        raise NotImplementedError
      end

      def reverse_order(scope)
        raise NotImplementedError
      end

      def timestamp_column?(scope, field)
        normalized_column_type(scope, field) == :timestamp
      end

      def contains(scope, field, value)
        raise NotImplementedError
      end

      def column_names(scope)
        raise NotImplementedError
      end

      def normalized_column_type(scope, field)
        raise NotImplementedError
      end

      def batch_each(scope, batch_size, &block)
        raise NotImplementedError
      end

      def append_column_queries(assets, columns)
        raise NotImplementedError if columns.present?

        assets
      end

      def default_cache_key(asset)
        raise NotImplementedError
      end

      def default_preload(scope, value)
        raise NotImplementedError
      end

      def can_preload?(scope, association)
        raise NotImplementedError
      end

      protected

      def timestamp_class?(klass)
        TIMESTAMP_CLASSES.include?(klass)
      end
    end
  end
end
