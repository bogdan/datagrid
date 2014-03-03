module Datagrid
  module Drivers
    class AbstractDriver

      TIMESTAMP_CLASSES = [DateTime, Time, ActiveSupport::TimeWithZone]

      class_attribute :subclasses

      def self.inherited(base)
        super(base)
        self.subclasses ||= []
        self.subclasses << base
      end

      def self.guess_driver(scope)
        self.subclasses.find do |driver_class|
          driver_class.match?(scope)
        end || raise(Datagrid::ConfigurationError, "ORM Driver not found for scope: #{scope.inspect}.")
      end

      def self.match?(scope)
        raise NotImplementedError
      end

      def match?(scope)
        self.class.match?(scope)
      end

      def to_scope(scope, columns = [])
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
      
      def has_column?(scope, column_name)
        raise NotImplementedError
      end

      def reverse_order(scope)
        raise NotImplementedError
      end

      def is_timestamp?(scope, field)
        raise NotImplementedError
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

      def batch_map(scope, batch_size, &block)
        raise NotImplementedError
      end

      protected
      def timestamp_class?(klass)
        TIMESTAMP_CLASSES.include?(klass)
      end
    end
  end
end
