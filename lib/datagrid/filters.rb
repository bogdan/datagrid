require "active_support/core_ext/class/attribute"

module Datagrid
  module Filters

    require "datagrid/filters/base_filter"
    require "datagrid/filters/enum_filter"
    require "datagrid/filters/boolean_enum_filter"
    require "datagrid/filters/extended_boolean_filter"
    require "datagrid/filters/boolean_filter"
    require "datagrid/filters/date_filter"
    require "datagrid/filters/date_time_filter"
    require "datagrid/filters/default_filter"
    require "datagrid/filters/integer_filter"
    require "datagrid/filters/composite_filters"
    require "datagrid/filters/string_filter"
    require "datagrid/filters/float_filter"
    require "datagrid/filters/dynamic_filter"

    FILTER_TYPES = {
      :date => Filters::DateFilter,
      :datetime => Filters::DateTimeFilter,
      :string => Filters::StringFilter,
      :default => Filters::DefaultFilter,
      :eboolean => Filters::BooleanEnumFilter ,
      :xboolean => Filters::ExtendedBooleanFilter ,
      :boolean => Filters::BooleanFilter ,
      :integer => Filters::IntegerFilter,
      :enum => Filters::EnumFilter,
      :float => Filters::FloatFilter,
      :dynamic => Filters::DynamicFilter
    }

    def self.included(base) #:nodoc:
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

      # Returns filter definition object by name
      def filter_by_name(attribute)
        return attribute if attribute.is_a?(Datagrid::Filters::BaseFilter)
        self.filters.find do |filter|
          filter.name.to_sym == attribute.to_sym
        end
      end

      # Defines new datagrid filter.
      # This method automatically generates <tt>attr_accessor</tt> for filter name
      # and adds it to the list of datagrid attributes.
      #
      # Arguments:
      #
      # * <tt>name</tt> - filter name
      # * <tt>type</tt> - filter type that defines type case and GUI representation of a filter
      # * <tt>options</tt> - hash of options
      # * <tt>block</tt> - proc to apply the filter
      #
      # Available options:
      #
      # * <tt>:header</tt> - determines the header of the filter
      # * <tt>:default</tt> - the default filter value. Able to accept a <tt>Proc</tt> in case default should be recalculated
      # * <tt>:multiple</tt> -  if true multiple values can be assigned to this filter.
      #   By default multiple values are parsed from string using `,` separator.
      #   But you can specify a different separator as option value. Default: false.
      # * <tt>:allow_nil</tt> - determines if the value can be nil
      # * <tt>:allow_blank</tt> - determines if the value can be blank
      # * <tt>:before</tt> - determines the position of this filter,
      #   by adding it before the filter passed here (when using datagrid_form_for helper)
      # * <tt>:after</tt> - determines the position of this filter,
      #   by adding it after the filter passed here (when using datagrid_form_for helper)
      # * <tt>:dummy</tt> - if true, this filter will not be applied automatically
      #   and will be just displayed in form. In case you may want to apply it manually.
      #
      # See: https://github.com/bogdan/datagrid/wiki/Filters for examples
      def filter(name, type = :default, options = {}, &block)
        if type.is_a?(Hash)
          options = type
          type = :default
        end

        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class #{type.inspect} not found" unless klass

        position = Datagrid::Utils.extract_position_from_options(self.filters, options)
        filter = klass.new(self, name, options, &block)
        self.filters.insert(position, filter)

        datagrid_attribute(name) do |value|
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

      def initialize(*args, &block) # :nodoc:
        self.filters = self.class.filters.clone
        self.filters.each do |filter|
          self[filter.name] = filter.default(self)
        end
        super(*args, &block)
      end

      def assets # :nodoc:
        apply_filters(super, filters)
      end

      # Returns filter value for given filter definition
      def filter_value(filter)
        self[filter.name]
      end

      # Returns string representation of filter value
      def filter_value_as_string(name)
        filter = filter_by_name(name)
        value = filter_value(filter)
        if value.is_a?(Array) 
          value.map {|v| filter.format(v) }.join(filter.separator)
        else
          filter.format(value)
        end
      end

      # Returns filter object with the given name
      def filter_by_name(name)
        self.class.filter_by_name(name)
      end

      # Returns assets filtered only by specified filters
      # Allows partial filtering
      def filter_by(*filters)
        apply_filters(scope, filters.map{|f| filter_by_name(f)})
      end

      # Returns select options for specific filter or filter name
      # If given filter doesn't support select options raises `ArgumentError`
      def select_options(filter)
        filter = filter_by_name(filter)
        unless filter.class.included_modules.include?(::Datagrid::Filters::SelectOptions)
          raise ::Datagrid::ArgumentError, "#{filter.name} with type #{FILTER_TYPES.invert[filter.class].inspect} can not have select options"
        end
        filter.select(self)
      end

      protected

      def apply_filters(current_scope, filters)
        filters.inject(current_scope) do |result, filter|
          filter.apply(self, result, filter_value(filter))
        end
      end
    end # InstanceMethods

  end
end
