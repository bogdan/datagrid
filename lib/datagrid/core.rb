require "datagrid/drivers"
require "active_support/core_ext/class/attribute"
require "active_model/attribute_assignment"

module Datagrid
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
      end
    end

    module ClassMethods

      # @!visibility private
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
            instance_variable_set("@#{name}", instance_exec(value, &block))
          end
        end
      end

      # Defines a scope at class level
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

      protected

      def check_scope_defined!(message = nil)
        message ||= "#{self}.scope is not defined"
        raise(Datagrid::ConfigurationError, message) unless scope_value
      end

      def inherited(child_class)
        super(child_class)
        child_class.datagrid_attributes = self.datagrid_attributes.clone
      end

    end

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


    # @return [Hash<Symbol, Object>] grid attributes including filter values and ordering values
    def attributes
      result = {}
      self.datagrid_attributes.each do |name|
        result[name] = self[name]
      end
      result
    end

    # Updates datagrid attributes with a passed hash argument
    # @param attributes [Hash<Symbol, Object>]
    # @example
    #   grid = MyGrid.new
    #   grid.attributes = {first_name: 'John', last_name: 'Smith'}
    #   grid.first_name # => 'John'
    #   grid.last_name # => 'Smith'
    def attributes=(attributes)
      super(attributes)
    end

    # @return [Object] Any datagrid attribute value
    def [](attribute)
      self.public_send(attribute)
    end

    # Assigns any datagrid attribute
    # @param attribute [Symbol, String] Datagrid attribute name
    # @param value [Object] Datagrid attribute value
    # @return [void]
    def []=(attribute, value)
      self.public_send(:"#{attribute}=", value)
    end

    # @return [Object] a scope relation (e.g ActiveRecord::Relation) with all applied filters
    def assets
      scope
    end

    # Returns serializable query arguments skipping all nil values
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

    # @return [Hash<Symbol, Hash<Symbol, Object>>] query parameters to link this grid from a page
    # @example
    #   grid = ProductsGrid.new(category: 'dresses', available: true)
    #   Rails.application.routes.url_helpers.products_path(grid.query_params)
    #     # => "/products?products_grid[category]=dresses&products_grid[available]=true"
    def query_params(attributes = {})
      { param_name.to_sym => as_query.merge(attributes) }
    end

    # Redefines scope at instance level
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
      check_scope_defined!
      scope_value.call
    end

    # Resets current instance scope to default scope defined in a class
    # @return [void]
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

    # @!visibility private
    def check_scope_defined!(message = nil)
      self.class.send :check_scope_defined!, message
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

    # Resets loaded assets and column values cache
    # @return [void]
    def reset
      assets.reset
    end

    protected
    def sanitize_for_mass_assignment(attributes)
      forbidden_attributes_protection ? super(attributes) : attributes
    end
  end
end
