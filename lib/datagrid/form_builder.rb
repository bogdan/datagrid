require "action_view"

module Datagrid
  module FormBuilder

    # Returns a form input html for the corresponding filter name
    def datagrid_filter(filter_or_attribute, options = {}, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      options = add_html_classes(options, filter.name, datagrid_filter_html_class(filter))
      # Prevent partials option from appearing in HTML attributes
      options.delete(:partials) unless supports_partial?(filter)
      self.send(filter.form_builder_helper_name, filter, options, &block)
    end

    # Returns a form label html for the corresponding filter name
    def datagrid_label(filter_or_attribute, options_or_text = {}, options = {}, &block)
      filter = datagrid_get_filter(filter_or_attribute)
      text, options = options_or_text.is_a?(Hash) ? [filter.header, options_or_text] : [options_or_text, options]
      label(filter.name, text, options, &block)
    end

    def datagrid_extra_checkbox_options
      ::ActionPack::VERSION::MAJOR >= 4 ? {:include_hidden => false} : {}
    end

    protected
    def datagrid_boolean_enum_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

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
      filter = datagrid_get_filter(attribute_or_filter)
      text_field filter.name, options.reverse_merge(:value => object.filter_value_as_string(filter))
    end

    def datagrid_enum_filter(attribute_or_filter, options = {}, &block)
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.checkboxes?
        partial = partial_path(options, 'enum_checkboxes')
        options = add_html_classes(options, 'checkboxes')
        elements = object.select_options(filter).map do |element|
          text, value = @template.send(:option_text_and_value, element)
          checked = enum_checkbox_checked?(filter, value)
          [value, text, checked]
        end
        @template.render(
          :partial => partial,
          :locals => {
            :elements => elements, 
            :form => self, 
            :filter => filter,
            :options => options,
          } 
        )
      else
        if !options.has_key?(:multiple) && filter.multiple?
          options[:multiple] = true
        end
        select(
          filter.name, 
          object.select_options(filter) || [],
          {:include_blank => filter.include_blank,
           :prompt => filter.prompt,
           :include_hidden => false},
           options, &block
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
      options = options.merge(:name => input_name)
      field_input = select(
        filter.name,
        object.select_options(filter) || [],
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
        partial = partial_path(options, 'range_filter')
        options = options.merge(:multiple => true)


        from_options = datagrid_range_filter_options(object, filter, :from, options)
        to_options = datagrid_range_filter_options(object, filter, :to, options)
        from_input = text_field(filter.name, from_options)
        to_input = text_field(filter.name, to_options)

        format_key = "datagrid.filters.#{type}.range_format"
        separator_key = "datagrid.filters.#{type}.range_separator"
        # 2 inputs: "from date" and "to date" to specify a range
        if I18n.exists?(separator_key)
          # Support deprecated translation option: range_separator
          warn_deprecated_range_localization(separator_key)
          separator = I18n.t(separator_key, default: '').presence
          [from_input, separator, to_input].join.html_safe
        elsif I18n.exists?(format_key)
          # Support deprecated translation option: range_format
          warn_deprecated_range_localization(format_key)
          I18n.t(format_key, :from_input => from_input, :to_input => to_input).html_safe
        else
          # More flexible way to render via partial
          @template.render :partial => partial, :locals => {
            :from_options => from_options, :to_options => to_options, :filter => filter, :form => self
          }
        end
      else
        datagrid_default_filter(filter, options)
      end
    end

    def warn_deprecated_range_localization(key)
      Datagrid::Utils.warn_once(
        "#{key} localization key is deprectated. " +
        "Customize formatting by rake datagrid:copy_partials and editing app/views/datagrid/range_filter partial."
      )
    end

    def datagrid_range_filter_options(object, filter, type, options)
      type_method_map = {:from => :first, :to => :last}
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
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_float_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:float, attribute_or_filter, options)
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

    def partial_path(options, name)
      if partials = options.delete(:partials)
        partial_name = File.join(partials, name)
        # Second argument is []: no magical namespaces to lookup added from controller 
        if @template.lookup_context.template_exists?(partial_name, [], true)
          return partial_name
        end
      end
      File.join('datagrid', name)
    end

    def supports_partial?(filter)
      (filter.supports_range? && filter.range?) || (filter.type == :enum && filter.checkboxes?)
    end

    class Error < StandardError
    end
  end
end
