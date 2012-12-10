require "action_view"

module Datagrid
  module FormBuilder

    def datagrid_filter(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      options = Datagrid::Utils.add_html_classes(options, filter.name, datagrid_filter_html_class(filter))
      self.send(filter.form_builder_helper_name, filter, options)
    end

    def datagrid_label(filter_or_attribute, options = {})
      filter = datagrid_get_filter(filter_or_attribute)
      self.label(filter.name, filter.header, options)
    end

    protected
    def datagrid_boolean_enum_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

    def datagrid_boolean_filter(attribute_or_filter, options = {})
      check_box(datagrid_get_attribute(attribute_or_filter), options)
    end

    def datagrid_date_filter(attribute_or_filter, options = {})
      datagrid_range_filter(:date, attribute_or_filter, options)
    end

    def datagrid_default_filter(attribute_or_filter, options = {})
      text_field datagrid_get_attribute(attribute_or_filter), options
    end

    def datagrid_enum_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if !options.has_key?(:multiple) && filter.multiple
        options[:multiple] = true
      end
      select filter.name, filter.select(object) || [], {:include_blank => filter.include_blank, :prompt => filter.prompt}, options
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.multiple && self.object[filter.name].blank?
        options[:value] = ""
      end
      datagrid_range_filter(:integer, filter, options)
    end

    def datagrid_range_filter(type, attribute_or_filter, options = {})
      filter = datagrid_get_filter(attribute_or_filter)
      if filter.range?
        options = options.merge(:multiple => true)

        from_options = Datagrid::Utils.add_html_classes(options, "from")
        from_value = object[filter.name].try(:first)

        to_options = Datagrid::Utils.add_html_classes(options, "to")
        to_value = object[filter.name].try(:last)
        # 2 inputs: "from date" and "to date" to specify a range
        [
          text_field(filter.name, from_options.merge!(:value => from_value)),
          I18n.t("datagrid.misc.#{type}_range_separator", :default => "<span class=\"separator #{type}\"> - </span>"),
          text_field(filter.name, to_options.merge!(:value => to_value))
        ].join.html_safe
      else
        text_field(filter.name, options)
      end
    end

    def datagrid_string_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_float_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def datagrid_get_attribute(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ?  attribute_or_filter : attribute_or_filter.name
    end

    def datagrid_get_filter(attribute_or_filter)
      if attribute_or_filter.is_a?(Symbol)
        object.class.filter_by_name(attribute_or_filter) ||
          raise(Error, "filter #{attribute_or_filter} not found")
      else
        attribute_or_filter
      end
    end

    def datagrid_filter_html_class(filter)
      filter.class.to_s.demodulize.underscore
    end

    class Error < StandardError
    end
  end
end


