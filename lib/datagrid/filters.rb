require "active_support/core_ext/class/attribute"

module Datagrid
  module Filters

    require "datagrid/filters/base_filter"
    require "datagrid/filters/enum_filter"
    require "datagrid/filters/boolean_enum_filter"
    require "datagrid/filters/boolean_filter"
    require "datagrid/filters/date_filter"
    require "datagrid/filters/default_filter"
    require "datagrid/filters/integer_filter"
    require "datagrid/filters/composite_filters"
    require "datagrid/filters/string_filter"
    require "datagrid/filters/float_filter"

    FILTER_TYPES = {
      :date => Filters::DateFilter,
      :string => Filters::StringFilter,
      :default => Filters::DefaultFilter,
      :eboolean => Filters::BooleanEnumFilter ,
      :boolean => Filters::BooleanFilter ,
      :integer => Filters::IntegerFilter,
      :enum => Filters::EnumFilter,
      :float => Filters::FloatFilter,
    }

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core
        include Datagrid::Filters::CompositeFilters
        class_attribute :filters
        self.filters = []

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def filter_by_name(attribute)
        self.filters.find do |filter|
          filter.name.to_sym == attribute.to_sym
        end
      end

      # Defines new datagrid filter
      # 
      # Arguments:
      #
      #   * <tt>name</tt> - filter name
      #   * <tt>options</tt> - hash of options
      #   * <tt>block</tt> - proc to apply the filter
      #
      # Available options:
      #   
      #   * <tt>:header</tt> - determines the header of the filter
      #   * <tt>:default</tt> - the default filter value
      #   * <tt>:multiple</tt> - determines if more than one option can be selected
      #   * <tt>:allow_nil</tt> - determines if the value can be nil
      #   * <tt>:allow_blank</tt> - determines if the value can be blank
      #   * <tt>:before</tt> - determines the position of this filter, by adding it before the filter passed here (when using datagrid_form_for helper)
      #   * <tt>:after</tt> - determines the position of this filter, by adding it after the filter passed here (when using datagrid_form_for helper)
      #
      # See: https://github.com/bogdan/datagrid/wiki/Columns for examples
      def filter(attribute, *args, &block)
        options = args.extract_options!
        type = args.shift || :default

        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class #{type.inspect} not found" unless klass

        position = Datagrid::Utils.extract_position_from_options(self.filters, options)
        filter = klass.new(self, attribute, options, &block)
        self.filters.insert(position, filter)

        datagrid_attribute(attribute) do |value|
          filter.parse_values(value)
        end

      end

      protected

      def inherited(child_class)
        super(child_class)
        child_class.filters = self.filters.clone
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
          result = filter.apply(self, result, filter_value(filter))
        end
        result
      end

      def filters
        self.class.filters
      end

      def filter_value(filter)
        self[filter.name]
      end

      # Returns filter object with the given name
      def filter_by_name(name)
        self.class.filter_by_name(name)
      end

    end # InstanceMethods

  end
end
