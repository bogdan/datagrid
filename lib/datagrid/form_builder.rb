require "action_view"

module Datagrid
  module FormBuilder
    # @param filter_or_attribute [Datagrid::Filters::BaseFilter, String, Symbol] filter object or filter name
    # @param options [Hash] options of rails form input helper
    # @return [String] a form input html for the corresponding filter name
    #   * <tt>select</tt> for enum, xboolean filter types
    #   * <tt>check_box</tt> for boolean filter type
    #   * <tt>text_field</tt> for other filter types
    def datagrid_filter(filter_or_attribute, partials: nil, **options, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      options = {
        **filter.input_options,
        **add_html_classes(options, filter.name, datagrid_filter_html_class(filter)),
      }
      self.send(filter.form_builder_helper_name, filter, options, &block)
    end

    # @param filter_or_attribute [Datagrid::Filters::BaseFilter, String, Symbol] filter object or filter name
    # @param text [String, nil] label text, defaults to <tt>filter.header</tt>
    # @param options [Hash] options of rails <tt>label</tt> helper
    # @return [String] a form label html for the corresponding filter name
    def datagrid_label(filter_or_attribute, text = nil, **options, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      label(filter.name, text || filter.header, **filter.label_options, **options, &block)
    end

    def datagrid_filter_input(attribute_or_filter, **options)
      filter = datagrid_get_filter(attribute_or_filter)
      text_field filter.name, value: object.filter_value_as_string(filter), **options
    end

    protected
    def datagrid_extended_boolean_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

    def datagrid_boolean_filter(attribute_or_filter, options = {})
      check_box(datagrid_get_attribute(attribute_or_filter), options)
    end

    def datagrid_date_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:date, attribute_or_filter, options)
    end

    def datagrid_date_time_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:datetime, attribute_or_filter, options)
    end

    def datagrid_default_filter(attribute_or_filter, options = {})
      datagrid_filter_input(attribute_or_filter, **options)
    end

    def datagrid_enum_filter(attribute_or_filter, options = {}, &block)
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.checkboxes?
        options = add_html_classes(options, 'checkboxes')
        elements = object.select_options(filter).map do |element|
          text, value = @template.send(:option_text_and_value, element)
          checked = enum_checkbox_checked?(filter, value)
          [value, text, checked]
        end
        render_partial(
          'enum_checkboxes',
          {
            elements: elements,
            form: self,
            filter: filter,
            options: options,
          }
        )
      else
        select(
          filter.name,
          object.select_options(filter) || [],
          {
            include_blank: filter.include_blank,
            prompt: filter.prompt,
            include_hidden: false
          },
           multiple: filter.multiple?,
           **options,
           &block
        )
      end
    end

    def enum_checkbox_checked?(filter, option_value)
      current_value = object.send(filter.name)
      if current_value.respond_to?(:include?)
        # Typecast everything to string
        # to remove difference between String and Symbol
        current_value.map(&:to_s).include?(option_value.to_s)
      else
        current_value.to_s == option_value.to_s
      end
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.multiple? && object[filter.name].blank?
        options[:value] = ""
      end
      datagrid_range_filter(:integer, filter, options)
    end

    def datagrid_dynamic_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      input_name = "#{object_name}[#{filter.name.to_s}][]"
      field, operation, value = object.filter_value(filter)
      options = options.merge(name: input_name)
      field_input = dynamic_filter_select(
        filter.name,
        object.select_options(filter) || [],
        {
          include_blank: filter.include_blank,
          prompt: filter.prompt,
          include_hidden: false,
          selected: field
        },
        add_html_classes(options, "field")
      )
      operation_input = dynamic_filter_select(
        filter.name, filter.operations_select,
        {
          include_blank: false,
          include_hidden: false,
          prompt: false,
          selected: operation,
        },
        add_html_classes(options, "operation")
      )
      value_input = text_field(filter.name, **add_html_classes(options, "value"), value: value)
      [field_input, operation_input, value_input].join("\n").html_safe
    end

    def dynamic_filter_select(name, variants, select_options, html_options)
      if variants.size <= 1
        value = variants.first
        # select options format may vary
        value = value.last if value.is_a?(Array)
        # don't render any visible input when there is nothing to choose from
        hidden_field(name, **html_options, value: value)
      else
        select(name, variants, select_options, html_options)
      end
    end

    def datagrid_range_filter(type, attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.range?
        options = options.merge(multiple: true)
        from_options = datagrid_range_filter_options(object, filter, :from, options)
        to_options = datagrid_range_filter_options(object, filter, :to, options)
        render_partial 'range_filter', {
          from_options: from_options, to_options: to_options, filter: filter, form: self
        }
      else
        datagrid_filter_input(filter, **options)
      end
    end

    def datagrid_range_filter_options(object, filter, type, options)
      type_method_map = {from: :first, to: :last}
      options = add_html_classes(options, type)
      options[:value] = filter.format(object[filter.name].try(type_method_map[type]))
      # In case of datagrid ranged filter
      # from and to input will have same id
      if !options.key?(:id)
        # Rails provides it's own default id for all inputs
        # In order to prevent that we assign no id by default
        options[:id] = nil
      elsif options[:id].present?
        # If the id was given we prefix it
        # with from_ and to_ accordingly
        options[:id] = [type, options[:id]].join("_")
      end
      options
    end

    def datagrid_string_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:string, attribute_or_filter, options)
    end

    def datagrid_float_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:float, attribute_or_filter, options)
    end

    def datagrid_get_attribute(attribute_or_filter)
      Utils.string_like?(attribute_or_filter) ? attribute_or_filter : attribute_or_filter.name
    end

    def datagrid_get_filter(attribute_or_filter)
      if Utils.string_like?(attribute_or_filter)
        object.class.filter_by_name(attribute_or_filter) ||
          raise(Error, "Datagrid filter #{attribute_or_filter} not found")
      else
        attribute_or_filter
      end
    end

    def datagrid_filter_html_class(filter)
      filter.class.to_s.demodulize.underscore
    end

    def add_html_classes(options, *classes)
      Datagrid::Utils.add_html_classes(options, *classes)
    end

    def partial_path(name)
      if partials = self.options[:partials]
        partial_name = File.join(partials, name)
        # Second argument is []: no magical namespaces to lookup added from controller
        if @template.lookup_context.template_exists?(partial_name, [], true)
          return partial_name
        end
      end
      File.join('datagrid', name)
    end

    def render_partial(name, locals)
      @template.render partial: partial_path(name), locals: locals
    end

    class Error < StandardError
    end
  end
end
