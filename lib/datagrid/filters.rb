module Datagrid
  module Filters

    require "datagrid/filters/base_filter"
    require "datagrid/filters/enum_filter"
    require "datagrid/filters/boolean_enum_filter"
    require "datagrid/filters/boolean_filter"
    require "datagrid/filters/date_filter"
    require "datagrid/filters/default_filter"
    require "datagrid/filters/filter_eval"
    require "datagrid/filters/integer_filter"
    require "datagrid/filters/composite_filters"

    FILTER_TYPES = {
      :date => Filters::DateFilter,
      :string => Filters::DefaultFilter,
      :default => Filters::DefaultFilter,
      :eboolean => Filters::BooleanEnumFilter ,
      :boolean => Filters::BooleanFilter ,
      :integer => Filters::IntegerFilter,
      :enum => Filters::EnumFilter,
    }

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core
        include Datagrid::Filters::CompositeFilters

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def filters
        @filters ||= []
      end

      def filter_by_name(attribute)
        self.filters.find do |filter|
          filter.name.to_sym == attribute.to_sym
        end
      end


      # Defines the accessible attribute that is used to filter
      # scope by the specified value with specified code.
      # 
      # Example:
      #     
      #   class UserGrid 
      #     include Datagrid
      #
      #     filter(:name)
      #     filter(:posts_count, :integer) do |value|
      #       self.where(["posts_count >= ?", value])
      #     end
      #
      #     scope do
      #       User.order("users.created_at desc")
      #     end
      #   end
      #
      # Each filter becomes grid attribute.
      # In order to create grid that display all users with name 'John' that have more than zero posts:
      #
      #   grid = UserGrid.new(:posts_count => 1, :name => "John")
      #   grid.assets # SELECT * FROM users WHERE users.posts_count > 1 AND name = 'John'
      #
      # Important! Take care about non-breaking the filter chain and force objects loading in filter.
      # The filter block should always return a <tt>ActiveRecord::Scope</tt> rather than <tt>Array</tt>
      #
      # = Default filter block
      #
      # If no block given filter is generated automatically as simple select by filter name from scope.
      #
      # = Filter types
      #
      # Filter does types conversion automatically.
      # The following filter types are supported:
      #
      # * <tt>:string</tt> (default) - converts value to string
      # * <tt>:date</tt> - converts value to date using date parser
      # * <tt>:enum</tt> - designed to be collection select. Additional options for easy form generation:
      #   * <tt>:select</tt> (required) - collection of values to match agains.
      # * <tt>:boolean</tt> - converts value to true or false depending on whether it looks truly or falsy
      # * <tt>:eboolean</tt> - subtype of enum filter that provides select of "Yes", "No" and "Any". Could be useful.
      # * <tt>:integer</tt> - converts given value to integer.
      #   
      # = Default filter options
      #
      # Options that could be passed to any filter type:
      #
      # * <tt>:header</tt> - human readable name of the filter. Default: generated from the filter name.
      # * <tt>:default</tt> - default value of the filter. Default: nil.
      # * <tt>:multiple</tt> - if true multiple values can be assigned to this filter. Default: false.
      # * <tt>:allow_nil</tt> - determines if filter should be called if filter value is nil. Default: false.
      # * <tt>:allow_blank</tt> - determines if filter should be called if filter value is #blank?. Default: false.
      #
      def filter(attribute, type = :string, options = {}, &block)

        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class not found" unless klass

        block ||= default_filter(attribute)

        filter = klass.new(self, attribute, options, &block)
        self.filters << filter

        datagrid_attribute(attribute) do |value|
          filter.format_values(value)
        end

      end

      protected
      def default_filter(attribute)
        if self.scope.column_names.include?(attribute.to_s)
          lambda do |value|
            self.scoped(:conditions => {attribute => value})
          end
        else
          raise ConfigurationError, "Not able to generate default filter. No column '#{attribute}' in #{self.scope.table_name}."
        end
      end

    end # ClassMethods

    module InstanceMethods

      def initialize(*args, &block)
        self.filters.each do |filter|
          self[filter.name] = filter.default
        end
        super(*args, &block)
      end

      def assets
        result = super
        self.class.filters.each do |filter|
          result = filter.apply(result, filter_value(filter))
        end
        result
      end

      def filters
        self.class.filters
      end

      def filter_value(filter)
        self[filter.name]
      end

    end # InstanceMethods

  end
end
