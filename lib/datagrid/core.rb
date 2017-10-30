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

        class_attribute :dynamic_block, :instance_writer => false
        class_attribute :forbidden_attributes_protection, instance_writer: false
        self.forbidden_attributes_protection = false
        if defined?(::ActiveModel::AttributeAssignment)
          include ::ActiveModel::AttributeAssignment
        end
      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def datagrid_attribute(name, &block) #:nodoc:
        unless datagrid_attributes.include?(name)
          block ||= lambda do |value|
            value
          end
          datagrid_attributes << name
          define_method name do
            instance_variable_get("@#{name}")
          end

          define_method :"#{name}=" do |value|
            instance_variable_set("@#{name}", instance_exec(value, &block))
          end
        end
      end

      # Defines a scope at class level
      def scope(&block)
        if block
          current_scope = scope_value
          self.scope_value = proc {
            Datagrid::Utils.apply_args(current_scope ? current_scope.call : nil, &block)
          }
          self
        else
          check_scope_defined!
          scope_value.call
        end
      end

      def driver #:nodoc:
        @driver ||= Drivers::AbstractDriver.guess_driver(scope).new
      end

      # Allows dynamic columns definition, that could not be defined at class level
      #
      #   class MerchantsGrid
      #
      #     scope { Merchant }
      #
      #     column(:name)
      #
      #     dynamic do
      #       PurchaseCategory.all.each do |category|
      #         column(:"#{category.name.underscore}_sales") do |merchant|
      #           merchant.purchases.where(:category_id => category.id).count
      #         end
      #       end
      #     end
      #   end
      #
      #   grid = MerchantsGrid.new
      #   grid.data # => [
      #             #      [ "Name",   "Swimwear Sales", "Sportswear Sales", ... ]
      #             #      [ "Reebok", 2083382,            8382283,          ... ]
      #             #      [ "Nike",   8372283,            18734783,         ... ]
      #             #    ]
      def dynamic(&block)
        previous_block = dynamic_block
        self.dynamic_block =
          if previous_block
            proc {
              instance_eval(&previous_block)
              instance_eval(&block)
            }
          else
            block
          end
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

      def initialize(attributes = nil, &block)
        super()

        if attributes
          self.attributes = attributes
        end

        instance_eval(&dynamic_block) if dynamic_block
        if block_given?
          self.scope(&block)
        end
      end

      # Returns a hash of grid attributes including filter values
      # and ordering values
      def attributes
        result = {}
        self.datagrid_attributes.each do |name|
          result[name] = self[name]
        end
        result
      end

      # Alias for <tt>send</tt> method
      def [](attribute)
        self.send(attribute)
      end

      def []=(attribute, value)
        self.send(:"#{attribute}=", value)
      end

      # Returns a scope(e.g ActiveRecord::Relation) with all applied filters
      def assets
        driver.to_scope(scope)
      end


      # Updates datagrid attributes with a passed hash argument
      def attributes=(attributes)
        if respond_to?(:assign_attributes)
          if !forbidden_attributes_protection && attributes.respond_to?(:permit!)
            attributes.permit!
          end
          assign_attributes(attributes)
        else
          attributes.each do |name, value|
            self[name] = value
          end
          self
        end
      end

      # Returns serializable query arguments skipping all nil values
      def as_query
        attributes = self.attributes.clone
        attributes.each do |key, value|
          attributes.delete(key) if value.nil?
        end
        attributes
      end

      # Redefines scope at instance level
      #
      #   class MyGrid
      #     scope { Article.order('created_at desc') }
      #   end
      #
      #   grid = MyGrid.new
      #   grid.scope do |scope|
      #     scope.where(:author_id => current_user.id)
      #   end
      #   grid.assets
      #       # => SELECT * FROM articles WHERE author_id = ?
      #       #    ORDER BY created_at desc
      #
      def scope(&block)
        if block_given?
          current_scope = scope
          self.scope_value = proc {
            Datagrid::Utils.apply_args(current_scope, &block)
          }
          self
        else
          check_scope_defined!
          scope_value.call
        end
      end

      # Resets current instance scope to default scope defined in a class
      def reset_scope
        self.scope_value = self.class.scope_value
      end

      # Returns true if the scope was redefined for this instance of grid object
      def redefined_scope?
        self.class.scope_value != scope_value
      end

      def driver #:nodoc:
        self.class.driver
      end

      def check_scope_defined!(message = nil) #:nodoc:
        self.class.send :check_scope_defined!, message
      end

      def inspect
        attrs = attributes.map do |key, value|
          "#{key}: #{value.inspect}"
        end.join(", ")
        "#<#{self.class} #{attrs}>"
      end

      def ==(other)
        self.class == other.class &&
          attributes == other.attributes &&
          scope == other.scope
      end
    end # InstanceMethods
  end
end
