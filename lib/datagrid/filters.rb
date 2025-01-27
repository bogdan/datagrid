# frozen_string_literal: true

require "active_support/core_ext/class/attribute"

module Datagrid
  # Defines the accessible attribute that is used to filter
  # the scope by the specified value with specified code.
  #
  #     class UserGrid < ApplicationGrid
  #       scope do
  #         User
  #       end
  #
  #       filter(:name)
  #       filter(:posts_count, :integer) do |value|
  #         self.where(["posts_count >= ?", value])
  #       end
  #     end
  #
  # Each filter becomes a grid attribute.
  #
  # To create a grid displaying all users with the name 'John' who have more than zero posts:
  #
  #     grid = UserGrid.new(posts_count: 1, name: "John")
  #     grid.assets # SELECT * FROM users WHERE users.posts_count > 1 AND name = 'John'
  #
  # Filter blocks should always return a chainable ORM object (e.g., `ActiveRecord::Relation`) rather than an `Array`.
  #
  # # Filter Block
  #
  # Filter blocks should have at least one argument representing the value assigned to the grid object attribute:
  #
  #     filter(:name, :string) # { |value| where(name: value) }
  #
  # You can pass additional arguments:
  #
  #     filter(:name, :string) { |value, scope| scope.where("name ilike ?", "%#{value}%") }
  #     filter(:name, :string) do |value, scope, grid|
  #       scope.where("name #{grid.predicate} ?", "%#{value}%")
  #     end
  #
  # # Filter Types
  #
  # Filters perform automatic type conversion. Supported filter types include:
  #
  # - `default`
  # - `date`
  # - `datetime`
  # - `enum`
  # - `boolean`
  # - `xboolean`
  # - `integer`
  # - `float`
  # - `string`
  # - `dynamic`
  #
  # ## Default
  #
  # `:default` - Leaves the value as is.
  #
  # ## Date
  #
  # `:date` - Converts value to a date. Supports the `:range` option to accept date ranges.
  #
  #     filter(:created_at, :date, range: true, default: proc { 1.month.ago.to_date..Date.today })
  #
  # ## Datetime
  #
  # `:datetime` - Converts value to a timestamp. Supports the `:range` option to accept time ranges.
  #
  #     filter(:created_at, :datetime, range: true, default: proc { 1.hour.ago..Time.now })
  #
  # ## Enum
  #
  # `:enum` - For collection selection with options like `:select` and `:multiple`.
  #
  #     filter(:user_type, :enum, select: ['Admin', 'Customer', 'Manager'])
  #     filter(:category_id, :enum, select: proc { Category.all.map { |c| [c.name, c.id] } }, multiple: true)
  #
  # ## Boolean
  #
  # `:boolean` - Converts value to `true` or `false`.
  #
  # ## Xboolean
  #
  # `:xboolean` - Subtype of `enum` filter that provides "Yes", "No", and "Any" options.
  #
  #     filter(:active, :xboolean)
  #
  # ## Integer
  #
  # `:integer` - Converts value to an integer. Supports the `:range` option.
  #
  #     filter(:posts_count, :integer, range: true, default: (1..nil))
  #
  # ## String
  #
  # `:string` - Converts value to a string.
  #
  #     filter(:email, :string)
  #
  # ## Dynamic
  #
  # Provides a builder for dynamic SQL conditions.
  #
  #     filter(:condition1, :dynamic)
  #     filter(:condition2, :dynamic)
  #     UsersGrid.new(condition1: [:name, "=~", "John"], condition2: [:posts_count, ">=", 1])
  #     UsersGrid.assets # SELECT * FROM users WHERE name like '%John%' and posts_count >= 1
  #
  # # Filter Options
  #
  # Options that can be passed to any filter:
  #
  # - `:header` - Human-readable filter name (default: generated from the filter name).
  # - `:default` - Default filter value (default: `nil`).
  # - `:multiple` - Allows multiple values (default: `false`).
  # - `:allow_nil` - Whether to apply the filter when the value is `nil` (default: `false`).
  # - `:allow_blank` - Whether to apply the filter when the value is blank (default: `false`).
  #
  # Example:
  #
  #     filter(:id, :integer, header: "Identifier")
  #     filter(:created_at, :date, range: true, default: proc { 1.month.ago.to_date..Date.today })
  #
  # # Localization
  #
  # Filter labels can be localized or specified via the `:header` option:
  #
  #     filter(:created_at, :date, header: "Creation date")
  #     filter(:created_at, :date, header: proc { I18n.t("creation_date") })
  module Filters
    require "datagrid/filters/base_filter"
    require "datagrid/filters/enum_filter"
    require "datagrid/filters/extended_boolean_filter"
    require "datagrid/filters/boolean_filter"
    require "datagrid/filters/date_filter"
    require "datagrid/filters/date_time_filter"
    require "datagrid/filters/default_filter"
    require "datagrid/filters/integer_filter"
    require "datagrid/filters/string_filter"
    require "datagrid/filters/float_filter"
    require "datagrid/filters/dynamic_filter"

    # @!visibility private
    FILTER_TYPES = {
      date: Filters::DateFilter,
      datetime: Filters::DateTimeFilter,
      string: Filters::StringFilter,
      default: Filters::DefaultFilter,
      xboolean: Filters::ExtendedBooleanFilter,
      boolean: Filters::BooleanFilter,
      integer: Filters::IntegerFilter,
      enum: Filters::EnumFilter,
      float: Filters::FloatFilter,
      dynamic: Filters::DynamicFilter,
    }.freeze

    # @!visibility private
    DEFAULT_FILTER_BLOCK = Object.new

    extend ActiveSupport::Concern

    included do
      include Datagrid::Core
      class_attribute :default_filter_options, instance_writer: false, default: {}
      class_attribute :filters_array, default: []
    end

    # Grid class methods related to filters
    module ClassMethods
      # @return [Datagrid::Filters::BaseFilter, nil] filter definition object by name
      def filter_by_name(attribute)
        if attribute.is_a?(Datagrid::Filters::BaseFilter)
          unless ancestors.include?(attribute.grid_class)
            raise ArgumentError, "#{attribute.grid_class}##{attribute.name} filter doen't belong to #{self.class}"
          end

          return attribute
        end
        filters.find do |filter|
          filter.name == attribute.to_sym
        end
      end

      # Defines new datagrid filter.
      # This method automatically generates <tt>attr_accessor</tt> for filter name
      # and adds it to the list of datagrid attributes.
      #
      # @param [Symbol] name filter name
      # @param [Symbol] type filter type that defines type case and GUI representation of a filter
      # @param [Hash] options hash of options
      # @yield [value, scope, grid] Block to apply the filter.
      # @yieldparam [Object] value The value assigned to the filter.
      # @yieldparam [Object] scope The current ORM scope being filtered.
      # @yieldparam [Datagrid::Base] grid The datagrid instance.
      # @return [Datagrid::Filters::BaseFilter] Filter definition object
      # @option options [String] header Determines the header of the filter.
      # @option options [Object, Proc] default The default filter value. Accepts a `Proc` to allow dynamic calculation.
      # @option options [Boolean] range Whether the filter accepts two values to define a range.
      #   Supported by types: `:integer`, `:float`, `:date`, `:datetime`, and `:string`.
      # @option options [Boolean, String] multiple If true, allows multiple values for the filter.
      #   Strings are parsed using a separator (default: `,`). Can accept a custom separator. Default: `false`.
      # @option options [Boolean] allow_nil Whether the filter value can be `nil`. Default: `false`.
      # @option options [Boolean] allow_blank Whether the filter value can be blank. Default: `false`.
      # @option options [Symbol] before Specifies the position of this filter by placing it before another filter.
      #   Used with the `datagrid_form_for` helper.
      # @option options [Symbol] after Specifies the position of this filter by placing it after another filter.
      #   Used with the `datagrid_form_for` helper.
      # @option options [Boolean] dummy If true, the filter is not applied automatically and
      #   is only displayed in the form. Useful for manual application.
      # @option options [Proc, Symbol] if Specifies a condition under which the filter is displayed and used.
      #   Accepts a block or the name of an instance method.
      # @option options [Proc, Symbol] unless Specifies a condition under which the filter is NOT displayed or used.
      #   Accepts a block or the name of an instance method.
      # @option options [Hash] input_options Options passed to the HTML input tag for rendering attributes.
      #   Use `input_options[:type]` to control the input type (e.g., `textarea`).
      # @option options [Hash] label_options Options passed to the HTML label tag for rendering attributes.
      # @see Datagrid::Filters
      def filter(name, type = :default, **options, &block)
        klass = type.is_a?(Class) ? type : FILTER_TYPES[type]
        raise ConfigurationError, "filter class #{type.inspect} not found" unless klass

        options_with_defaults = default_filter_options.merge(options)

        position = Datagrid::Utils.extract_position_from_options(filters_array, options_with_defaults)
        filter = klass.new(self, name, **options_with_defaults, &block)
        filters_array.insert(position, filter)

        datagrid_attribute(name) do |value|
          filter.parse_values(value)
        end
        filter
      end

      # @!visibility private
      def default_filter
        DEFAULT_FILTER_BLOCK
      end

      # @!visibility private
      def inspect
        "#{super}(#{filters_inspection})"
      end

      # @return [Array<Datagrid::Filters::BaseFilter>] all defined filters
      def filters
        filters_array
      end

      protected

      def inherited(child_class)
        super
        child_class.filters_array = filters_array.clone
      end

      def filters_inspection
        return "no filters" if filters.empty?

        filters.map do |filter|
          "#{filter.name}: #{filter.type}"
        end.join(", ")
      end
    end

    # @!visibility private
    def initialize(...)
      self.filters_array = self.class.filters_array.clone
      filters_array.each do |filter|
        value = filter.default(self)
        self[filter.name] = value unless value.nil?
      end
      super
    end

    # @!visibility private
    def assets
      apply_filters(super, filters)
    end

    # @return [Object] filter value for given filter definition
    def filter_value(filter)
      self[filter.name]
    end

    # @return [String] string representation of filter value
    def filter_value_as_string(name)
      filter = filter_by_name(name)
      value = filter_value(filter)
      if value.is_a?(Array)
        value.map { |v| filter.format(v) }.join(filter.separator)
      else
        filter.format(value)
      end
    end

    # @return [Datagrid::Filters::BaseFilter, nil] filter object with the given name
    def filter_by_name(name)
      self.class.filter_by_name(name)
    end

    # @return [Array<Object>] assets filtered only by specified filters
    def filter_by(*filters)
      apply_filters(scope, filters.map { |f| filter_by_name(f) })
    end

    # @return [Array] the select options for the filter
    # @raise [ArgumentError] if the filter doesn't support select options
    def select_options(filter)
      find_select_filter(filter).select(self)
    end

    # @return [void] sets all options as selected for a filter that has options
    def select_all(filter)
      filter = find_select_filter(filter)
      self[filter.name] = select_values(filter)
    end

    # @return [Array] all possible values for the filter
    def select_values(filter)
      find_select_filter(filter).select_values(self)
    end

    # @return [Array<Datagrid::Filters::BaseFilter>] all currently enabled filters
    def filters
      self.class.filters.select do |filter|
        filter.enabled?(self)
      end
    end

    # @!visibility private
    def default_filter
      self.class.default_filter
    end

    protected

    def find_select_filter(filter)
      filter = filter_by_name(filter)
      unless filter.class.included_modules.include?(::Datagrid::Filters::SelectOptions)
        type = FILTER_TYPES.invert[filter.class].inspect
        raise(
          ::Datagrid::ArgumentError,
          "#{self.class.name}##{filter.name} with type #{type} can not have select options",
        )
      end
      filter
    end

    def apply_filters(current_scope, filters)
      filters.inject(current_scope) do |result, filter|
        filter.apply(self, result, filter_value(filter))
      end
    end
  end
end
