require "datagrid/drivers"
require "active_support/core_ext/class/attribute"

module Datagrid
  module Core

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        class_attribute :scope_value
        class_attribute :datagrid_attributes
        self.datagrid_attributes = []
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

      def scope(&block)
        if block
          self.scope_value = block
        else
          check_scope_defined!
          scope_value.call
        end
      end

      def driver
        @driver ||= Drivers::AbstractDriver.guess_driver(scope).new
      end

      protected
      def check_scope_defined!(message = nil)
        message ||= "#{self}.scope is not defined"
        raise(Datagrid::ConfigurationError, message) unless scope_value
      end

      def inherited(child_class)
        super(child_class)
        child_class.datagrid_attributes = self.datagrid_attributes.clone
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
        self.datagrid_attributes.each do |name|
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
        driver.to_scope(scope)
      end

      def attributes=(attributes)
        attributes.each do |name, value|
          self[name] = value
        end
      end

      def paginate(*args, &block)
        ::Datagrid::Utils.warn_once("#paginate is deprecated. Call it like object.assets.paginate(...).")
        self.assets.paginate(*args, &block)
      end

      def scope(&block)
        if block_given?
          self.scope_value = block
          self
        else
          check_scope_defined!
          scope_value.call
        end
      end

      def driver
        self.class.driver
      end

      def check_scope_defined!(message = nil)
        self.class.send :check_scope_defined!, message
      end

    end # InstanceMethods
  end
end
