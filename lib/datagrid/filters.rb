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

      def filter(attribute, *args, &block)
        options = args.extract_options!
        type = args.shift || :default

        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class #{type.inspect} not found" unless klass


        filter = klass.new(self, attribute, options, &block)
        self.filters << filter

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

    end # InstanceMethods

  end
end
