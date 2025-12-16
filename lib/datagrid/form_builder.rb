# frozen_string_literal: true

require "action_view"
require "datagrid/deprecated_object"

module Datagrid
  module FormBuilder
    # @!visibility private
    TYPE_METHOD_MAP = {
      search: :search_field,
      textarea: :text_area,
      hidden: :hidden_field,
      number: :number_field,
    }.with_indifferent_access

    # @param filter_or_attribute [Datagrid::Filters::BaseFilter, String, Symbol] filter object or filter name
    # @param options [Hash] options of rails form input helper
    # @return [String] a form input html for the corresponding filter name
    #   * <tt>select</tt> for enum, xboolean filter types
    #   * <tt>check_box</tt> for boolean filter type
    #   * <tt>text_field</tt> for other filter types
    def datagrid_filter(filter_or_attribute, **options, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      if filter.range?
        datagrid_range_filter(filter, options, &block)
      elsif filter.enum_checkboxes?
        datagrid_enum_checkboxes_filter(filter, options, &block)
      elsif filter.type == :dynamic
        datagrid_dynamic_filter(filter, options, &block)
      else
        datagrid_filter_input(filter, **options, &block)
      end
    end

    # @param filter_or_attribute [Datagrid::Filters::BaseFilter, String, Symbol] filter object or filter name
    # @param text [String, nil] label text, defaults to <tt>filter.header</tt>
    # @param options [Hash] options of rails <tt>label</tt> helper
    # @return [String] a form label tag for the corresponding filter name
    def datagrid_label(filter_or_attribute, text = nil, **options, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      options = { **filter.label_options, **options }
      label(filter.name, text || filter.header, **options, &block)
    end

    # @param [Datagrid::Filters::BaseFilter, String, Symbol] attribute_or_filter filter object or filter name
    # @param options [Hash{Symbol => Object}] HTML attributes to assign to input tag
    #   * `type` - special attribute the determines an input tag to be made.
    #     Examples: `text`, `select`, `textarea`, `number`, `date` etc.
    # @return [String] an input tag for the corresponding filter name
    def datagrid_filter_input(attribute_or_filter, **options, &block)
      filter = datagrid_get_filter(attribute_or_filter)
      options = add_filter_options(filter, **options)
      type = options.delete(:type)&.to_sym
      if %i[datetime-local date].include?(type)
        if options.key?(:value) && options[:value].nil?
          # https://github.com/rails/rails/pull/53387
          options[:value] = ""
        end
      elsif options[:value]
        options[:value] = filter.format(options[:value])
      end
      case type
      when :"datetime-local"
        datetime_local_field filter.name, **options, &block
      when :date
        date_field filter.name, **options, &block
      when :checkbox
        value = options.fetch(:value, 1).to_s
        if filter.enum_checkboxes? && enum_checkbox_checked?(filter, value) && !options.key?(:checked)
          options[:checked] = true
        end
        check_box filter.name, options, value
      when :select
        select(
          filter.name,
          options.delete(:select_choices) || object.select_options(filter) || [],
          {
            include_blank: filter.include_blank,
            prompt: filter.prompt,
            include_hidden: false,
            **options.delete(:select_options),
          },
          multiple: filter.multiple?,
          **options,
          &block
        )
      else
        public_send(
          TYPE_METHOD_MAP[type] || :text_field,
          filter.name,
          value: object.filter_value_as_string(filter),
          **options,
          &block
        )
      end
    end

    protected

    def datagrid_enum_checkboxes_filter(filter, options = {})
      elements = object.select_options(filter).map do |element|
        text, value = @template.send(:option_text_and_value, element)
        checked = enum_checkbox_checked?(filter, value)
        [value, text, checked]
      end
      choices = elements.map do |value, text, *_|
        [value, text]
      end
      render_partial(
        "enum_checkboxes",
        {
          form: self,
          elements: Datagrid::DeprecatedObject.new(
            elements,
          ) do
            Datagrid::Utils.warn_once(
              <<~MSG,
                Using `elements` variable in enum_checkboxes view is deprecated, use `choices` instead.
              MSG
            )
          end,
          choices: choices,
          filter: filter,
          options: options,
        },
      )
    end

    def enum_checkbox_checked?(filter, option_value)
      current_value = object.filter_value(filter)
      if current_value.respond_to?(:include?)
        # Typecast everything to string
        # to remove difference between String and Symbol
        current_value.map(&:to_s).include?(option_value.to_s)
      else
        current_value.to_s == option_value.to_s
      end
    end

    def datagrid_dynamic_filter(filter, options = {})
      options = add_filter_options(filter, **options)
      field, operation, value = object.filter_value(filter)
      field_options = datagrid_dynamic_field_options(options: options, field: field, filter: filter)
      operation_options = datagrid_dynamic_operation_options(options: options, operation: operation, filter: filter)
      value_options = datagrid_dynamic_value_options(options: options, value: value, filter: filter)
      render_partial(
        "dynamic_filter",
        { filter: filter,
          form: self,
          field_options: field_options,
          operation_options: operation_options,
          value_options: value_options, },
      )
    end

    def datagrid_dynamic_field_options(options:, field:, filter:)
      options.merge(
        {
          type: :select,
          select_options: {
            selected: field,
          },
          name: @template.field_name(object_name, filter.name, "field"),
        },
      )
    end

    def datagrid_dynamic_operation_options(options:, operation:, filter:)
      options.merge(
        {
          type: :select,
          select_choices: filter.operations_select,
          select_options: {
            include_blank: false,
            prompt: false,
            selected: operation,
          },
          name: @template.field_name(object_name, filter.name, "operation"),
        },
      )
    end

    def datagrid_dynamic_value_options(options:, value:, filter:)
      options.merge(
        {
          value: value,
          name: @template.field_name(object_name, filter.name, "value"),
        },
      )
    end

    def datagrid_range_filter(filter, options = {})
      from_options = datagrid_range_filter_options(object, filter, :from, **options)
      to_options = datagrid_range_filter_options(object, filter, :to, **options)
      render_partial "range_filter", {
        from_options: from_options, to_options: to_options, filter: filter, form: self,
      }
    end

    def datagrid_range_filter_options(object, filter, section, **options)
      type_method_map = { from: :begin, to: :end }
      options[:value] = object[filter.name]&.public_send(type_method_map[section])
      options[:name] = @template.field_name(object_name, filter.name, section)
      options
    end

    def datagrid_get_filter(attribute_or_filter)
      return attribute_or_filter unless Utils.string_like?(attribute_or_filter)

      object.class.filter_by_name(attribute_or_filter) ||
        raise(ArgumentError, "Datagrid filter #{attribute_or_filter} not found")
    end

    def partial_path(name)
      if (partials = options[:partials])
        partial_name = File.join(partials, name)
        # Second argument is []: no magical namespaces to lookup added from controller
        return partial_name if @template.lookup_context.template_exists?(partial_name, [], true)
      end
      File.join("datagrid", name)
    end

    def render_partial(name, locals)
      @template.render partial: partial_path(name), locals: locals
    end

    def add_filter_options(filter, **options)
      { **filter.default_input_options, **filter.input_options, **options }
    end
  end
end
