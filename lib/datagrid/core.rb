# frozen_string_literal: true

require "datagrid/drivers"
require "active_support/core_ext/class/attribute"
require "active_model/attribute_assignment"

module Datagrid
  # Simple example of using Datagrid scope as the assets source to be queried from the database.
  #
  # In most cases, the scope is a model class with some default ORM scopes, like `order` or `includes`:
  #
  # The scope is also used to:
  # - Choose an ORM driver (e.g., Mongoid, ActiveRecord, etc.).
  # - Association preloading
  # - Columns Providing default order
  #
  # You can set the scope at class level or instance level.
  # Both having appropriate use cases
  #
  # @example Defining a scope in a grid class
  #   class ProjectsGrid < ApplicationGrid
  #     scope { Project.includes(:category) }
  #   end
  #
  # @example Setting a scope at the instance level
  #   grid = ProjectsGrid.new(grid_params) do |scope|
  #     scope.where(owner_id: current_user.id)
  #   end
  #
  #   grid.assets # => SELECT * FROM projects WHERE projects.owner_id = ? AND [other filtering conditions]
  #
  # @example Retrieving and redefining the scope
  #   grid.scope # => SELECT * FROM projects WHERE projects.user_id = ?
  #   grid.redefined_scope? # => true
  #
  #   # Reset scope to default class value
  #   grid.reset_scope
  #   grid.assets # => SELECT * FROM projects
  #   grid.redefined_scope? # => false
  #
  #   # Overwriting the scope (ignoring previously defined)
  #   grid.scope { current_user.projects }
  #   grid.redefined_scope? # => true
  module Core
    include ::ActiveModel::AttributeAssignment

    # @!visibility private
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class_attribute :scope_value
        class_attribute :datagrid_attributes, instance_writer: false, default: []
        class_attribute :dynamic_block, instance_writer: false
        class_attribute :forbidden_attributes_protection, instance_writer: false, default: false
        class_attribute :default_filter_options, default: {}
      end
    end

    module ClassMethods
      # @!visibility private
      def datagrid_attribute(name, &block)
        return if datagrid_attributes.include?(name)

        datagrid_attributes << name
        define_method name do
          instance_variable_get("@#{name}")
        end

        define_method :"#{name}=" do |value|
          instance_variable_set("@#{name}", block ? instance_exec(value, &block) : value)
        end
      end

      # Defines a relation scope of database models to be filtered
      # @return [void]
      # @example
      #   scope { User }
      #   scope { Project.where(deleted: false) }
      #   scope { Project.preload(:stages) }
      def scope(&block)
        if block
          current_scope = scope_value
          self.scope_value = proc {
            Datagrid::Utils.apply_args(current_scope ? current_scope.call : nil, &block)
          }
          self
        else
          scope = original_scope
          driver.to_scope(scope)
        end
      end

      # @!visibility private
      def original_scope
        check_scope_defined!
        scope_value.call
      end

      # @!visibility private
      def driver
        @driver ||= Drivers::AbstractDriver.guess_driver(scope_value.call).new
      end

      # Allows dynamic columns definition, that could not be defined at class level
      # Columns that depend on the database state or third party service
      # can be defined this way.
      # @param block [Proc] block that defines dynamic columns
      # @return [void]
      # @example
      #   class MerchantsGrid
      #
      #     scope { Merchant }
      #
      #     column(:name)
      #
      #     dynamic do
      #       PurchaseCategory.all.each do |category|
      #         column(:"#{category.name.underscore}_sales") do |merchant|
      #           merchant.purchases.where(category_id: category.id).count
      #         end
      #       end
      #     end
      #   end
      #
      #   ProductCategory.create!(name: 'Swimwear')
      #   ProductCategory.create!(name: 'Sportswear')
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

      # @!visibility private
      def check_scope_defined!(message = nil)
        message ||= "#{self}.scope is not defined"
        raise(Datagrid::ConfigurationError, message) unless scope_value
      end

      protected

      # @!visibility private
      def inherited(child_class)
        super
        child_class.datagrid_attributes = datagrid_attributes.clone
      end
    end

    # @param [Hash{String, Symbol => Object}] attributes a hash of attributes to initialize the object
    # @yield [block] an optional block that is passed to the scope method for further customization
    # @return [void] Initializes a new instance with optional attributes and an optional block.
    def initialize(attributes = nil, &block)
      super()

      self.attributes = attributes if attributes

      instance_eval(&dynamic_block) if dynamic_block
      return unless block_given?

      scope(&block)
    end

    # @return [Hash{Symbol => Object}] grid attributes including filter values and ordering values
    # @example
    #   class UsersGrid < ApplicationGrid
    #     scope { User }
    #     filter(:first_name, :string)
    #     filter(:last_name, :string)
    #   end
    #
    #   grid = UsersGrid.new(first_name: 'John', last_name: 'Smith')
    #   grid.attributes # => {first_name: 'John', last_name: 'Smith', order: nil, descending: nil}
    def attributes
      result = {}
      datagrid_attributes.each do |name|
        result[name] = self[name]
      end
      result
    end

    # @param [String, Symbol] attribute attribute name
    # @return [Object] Any datagrid attribute value
    def [](attribute)
      public_send(attribute)
    end

    # Assigns any datagrid attribute
    # @param attribute [Symbol, String] Datagrid attribute name
    # @param value [Object] Datagrid attribute value
    # @return [void]
    def []=(attribute, value)
      public_send(:"#{attribute}=", value)
    end

    # @return [Object] a scope relation (e.g ActiveRecord::Relation) with all applied filters
    def assets
      scope
    end

    # @return [Hash{Symbol => Object}] serializable query arguments skipping all nil values
    # @example
    #   grid = ProductsGrid.new(category: 'dresses', available: true)
    #   grid.as_query # => {category: 'dresses', available: true}
    def as_query
      attributes = self.attributes.clone
      attributes.each do |key, value|
        attributes.delete(key) if value.nil?
      end
      attributes
    end

    # @return [Hash{Symbol => Hash{Symbol => Object}}] query parameters to link this grid from a page
    # @example
    #   grid = ProductsGrid.new(category: 'dresses', available: true)
    #   Rails.application.routes.url_helpers.products_path(grid.query_params)
    #     # => "/products?products_grid[category]=dresses&products_grid[available]=true"
    def query_params(attributes = {})
      { param_name.to_sym => as_query.merge(attributes) }
    end

    # @return [void] redefines scope at instance level
    # @example
    #   class MyGrid
    #     scope { Article.order('created_at desc') }
    #   end
    #
    #   grid = MyGrid.new
    #   grid.scope do |scope|
    #     scope.where(author_id: current_user.id)
    #   end
    #   grid.assets
    #       # => SELECT * FROM articles WHERE author_id = ?
    #       #    ORDER BY created_at desc
    def scope(&block)
      if block_given?
        current_scope = scope
        self.scope_value = proc {
          Datagrid::Utils.apply_args(current_scope, &block)
        }
        self
      else
        scope = original_scope
        driver.to_scope(scope)
      end
    end

    # @!visibility private
    def original_scope
      self.class.check_scope_defined!
      scope_value.call
    end

    # @return [void] Resets current instance scope to default scope defined in a class
    def reset_scope
      self.scope_value = self.class.scope_value
    end

    # @return [Boolean] true if the scope was redefined for this instance of grid object
    def redefined_scope?
      self.class.scope_value != scope_value
    end

    # @!visibility private
    def driver
      self.class.driver
    end

    # @return [String] a datagrid attributes and their values in inspection form
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

    # @return [void] Resets loaded assets and column values cache
    def reset
      assets.reset
    end

    protected

    def sanitize_for_mass_assignment(attributes)
      if forbidden_attributes_protection
        super
      elsif defined?(ActionController::Parameters) && attributes.is_a?(ActionController::Parameters)
        attributes.to_unsafe_h
      else
        attributes
      end
    end
  end
end
