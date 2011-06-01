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
      :eboolean => Filters::BooleanEnumFilter ,
      :boolean => Filters::BooleanFilter ,
      :integer => Filters::IntegerFilter,
      :enum => Filters::EnumFilter,
    }

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

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
          filter.attribute.to_sym == attribute.to_sym
        end
      end

      def filter(attribute, type = :string, options = {}, &block)
        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class not found" unless klass
        block ||= lambda do |value|
          self.scoped(:conditions => {attribute => value})
        end

        filter = klass.new(self, attribute, options, &block)
        self.filters << filter

        report_attribute(attribute) do |value|
          filter.format(value)
        end

      end
    end # ClassMethods

    module InstanceMethods

      def initialize(*args, &block)
        self.filters.each do |filter|
          self[filter.attribute] = filter.default
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
        self[filter.attribute]
      end

    end # InstanceMethods

  end
end
