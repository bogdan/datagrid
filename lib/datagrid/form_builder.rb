require "action_view"

module Datagrid
  module FormBuilder

    # Returns a form input html for the corresponding filter name
    def datagrid_filter(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      options = add_html_classes(options, filter.name, datagrid_filter_html_class(filter))
      self.send(filter.form_builder_helper_name, filter, options)
    end

    # Returns a form label html for the corresponding filter name
    def datagrid_label(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      self.label(filter.name, filter.header, options)
    end

    protected
    def datagrid_boolean_enum_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

    def datagrid_boolean_filter(attribute_or_filter, options = {})
      check_box(datagrid_get_attribute(attribute_or_filter), options.reverse_merge(datagrid_extra_checkbox_options))
    end

    def datagrid_date_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:date, attribute_or_filter, options)
    end

    def datagrid_default_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      text_field filter.name, options.reverse_merge(:value => object.filter_value_as_string(filter))
    end

    def datagrid_enum_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.checkboxes?
        filter.select(object).map do |element|
          text, value = @template.send(:option_text_and_value, element)
          id = [object_name, filter.name, value].join('_').underscore
          input = check_box(filter.name, datagrid_extra_checkbox_options.reverse_merge(:id => id, :multiple => true), value, nil)
          label(filter.name, input + text, options.reverse_merge(:for => id))
        end.join("\n").html_safe
      else
        if !options.has_key?(:multiple) && filter.multiple?
          options[:multiple] = true
        end
        select filter.name, filter.select(object) || [], {:include_blank => filter.include_blank, :prompt => filter.prompt, :include_hidden => false}, options
      end
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.multiple? && self.object[filter.name].blank?
        options[:value] = ""
      end
      datagrid_range_filter(:integer, filter, options)
    end

    def datagrid_dynamic_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      input_name = "#{object_name}[#{filter.name.to_s}][]"
      field, operation, value = object.filter_value(filter)
      options = options.merge(:name => input_name)
      field_input = select(
        filter.name,
        filter.select(object) || [],
        {
          :include_blank => filter.include_blank,
          :prompt => filter.prompt,
          :include_hidden => false,
          :selected => field
        },
        add_html_classes(options, "field")
      )
      operation_input = select(
        filter.name, filter.operations_select,
        {:include_blank => false, :include_hidden => false, :prompt => false, :selected => operation },
        add_html_classes(options, "operation")
      )
      value_input = text_field(filter.name, add_html_classes(options, "value").merge(:value => value))
      [field_input, operation_input, value_input].join("\n").html_safe
    end

    def datagrid_range_filter(type, attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.range?
        options = options.merge(:multiple => true)


        from_options = datagrid_range_filter_options(object, filter, :from, options)
        to_options = datagrid_range_filter_options(object, filter, :to, options)
        # 2 inputs: "from date" and "to date" to specify a range
        [
          text_field(filter.name, from_options),
          I18n.t("datagrid.filters.#{type}.range_separator"),
          text_field(filter.name, to_options)
        ].join.html_safe
      else
        datagrid_default_filter(filter, options)
      end
    end


    def datagrid_range_filter_options(object, filter, type, options)
      type_method_map = {:from => :first, :to => :last}
      options = add_html_classes(options, type)
      options[:value] = filter.format(object[filter.name].try(type_method_map[type]))
      # In case of datagrid ranged filter
      # from and to input will have same id
      options[:id] = if !options.key?(:id)
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
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_float_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_get_attribute(attribute_or_filter)
      Utils.string_like?(attribute_or_filter) ?  attribute_or_filter : attribute_or_filter.name
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

    def datagrid_extra_checkbox_options
      ::ActionPack::VERSION::MAJOR >= 4 ? {:include_hidden => false} : {}
    end

    class Error < StandardError
    end

  end
end


