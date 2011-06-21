module Datagrid
  module Core

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def datagrid_attribute(name, &block)
        unless datagrid_attributes.include?(name)
          block ||= lambda do |value|
            value
          end
          datagrid_attributes << name
          define_method name do
            instance_variable_get("@#{name}")
          end

          define_method :"#{name}=" do |value|
            instance_variable_set("@#{name}", block.call(value))
          end
        end
      end

      def datagrid_attributes
        @datagrid_attributes ||= []
      end

      def scope(&block)
        if block
          @scope = block
        else
          check_scope_defined!
          @scope.call
        end
      end

      def param_name
        self.to_s.underscore.split('/').last
      end

      protected
      def check_scope_defined!(message = "Scope not defined")
        raise(Datagrid::ConfigurationError, message) unless @scope
      end

    end # ClassMethods

    module InstanceMethods

      def initialize(attributes = nil)
        super()

        if attributes
          self.attributes = attributes
        end
      end

      def attributes
        result = {}
        self.class.datagrid_attributes.each do |name|
          result[name] = self[name]
        end
        result
      end

      def [](attribute)
        self.send(attribute)
      end

      def []=(attribute, value)
        self.send(:"#{attribute}=", value)
      end

      def assets
        scope.scoped({})
      end

      def attributes=(attributes)
        attributes.each do |name, value|
          self[name] = value
        end
      end

      def paginate(*args, &block)
        self.assets.paginate(*args, &block)
      end

      def scope
        self.class.scope
      end


      def param_name
        self.class.param_name
      end

      def to_key
        [self.class.param_name]
      end
      
      protected

      def check_scope_defined!(message)
        self.class.check_scope_defined!(message)
      end

    end # InstanceMethods
  end
end
