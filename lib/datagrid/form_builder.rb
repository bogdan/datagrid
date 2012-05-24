require "action_view"

module Datagrid
  module FormBuilder

    def datagrid_filter(filter_or_attribute, options = {})
      filter = get_filter(filter_or_attribute)
      options[:class] ||= ""
      options[:class] += " " unless options[:class].blank?
      options[:class] += "#{filter.name} #{datagrid_filter_html_class(filter)}"
      self.send(datagrid_filter_method(filter), filter, options)
    end

    def datagrid_label(filter_or_attribute, options = {})
      filter = get_filter(filter_or_attribute)
      self.label(filter.name, filter.header, options)
    end

    protected
    def datagrid_boolean_enum_filter(attribute_or_filter, options = {})
      datagrid_enum_filter(attribute_or_filter, options)
    end

    def datagrid_boolean_filter(attribute_or_filter, options = {})
      check_box(get_attribute(attribute_or_filter), options)
    end

    def datagrid_date_filter(attribute_or_filter, options = {})
      attribute = get_attribute(attribute_or_filter)
      text_field(attribute, options)
    end

    def datagrid_default_filter(attribute_or_filter, options = {})
      text_field get_attribute(attribute_or_filter), options
    end

    def datagrid_enum_filter(attribute_or_filter, options = {})
      filter = get_filter(attribute_or_filter)
      if !options.has_key?(:multiple) && filter.multiple
        options[:multiple] = true
      end
      select filter.name, filter.select || [], {:include_blank => filter.include_blank, :prompt => filter.prompt}, options
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      filter = get_filter(attribute_or_filter)
      if filter.multiple && self.object[filter.name].blank?
        options[:value] = ""
      end
      text_field filter.name, options
    end

    def datagrid_string_filter(attribute_or_filter, options = {})
      datagrid_default_filter(attribute_or_filter, options)
    end

    def get_attribute(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ?  attribute_or_filter : attribute_or_filter.name
    end

    def get_filter(attribute_or_filter)
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

    def datagrid_filter_method(filter)
      :"datagrid_#{filter.class.to_s.demodulize.underscore}"
    end

    class Error < StandardError
    end
  end
end


