module Datagrid
  module Drivers
    class AbstractDriver

      class_attribute :subclasses

      def self.inherited(base)
        super(base)
        self.subclasses ||= []
        self.subclasses << base
      end

      def self.guess_driver(scope)
        klass = self.subclasses.find do |driver_class|
          driver_class.match?(scope)
        end || raise(Datagrid::ConfigurationError, "ORM Driver not found for scope: #{scope.inspect}.")
      end


      #TODO api declaration
      
    end
  end
end
