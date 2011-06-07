require "action_view"

module Datagrid
  module FormBuilder

    def datagrid_filter(filter_or_attribute, options = {})
      filter = get_filter(filter_or_attribute)
      options[:class] ||= ""
      options[:class] += " " unless options[:class].blank?
      options[:class] += "#{filter.name} #{datagrid_filter_class(filter.class)}"
      self.send(:"datagrid_#{filter.class.to_s.underscore.split('/').last}", filter, options)
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
      select filter.name, filter.select_for(self.object) || [], {:include_blank => filter.include_blank}, {:multiple => filter.multiple}.merge(options)
    end

    def datagrid_integer_filter(attribute_or_filter, options = {})
      text_field get_attribute(attribute_or_filter), options
    end

    def get_attribute(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ?  attribute_or_filter : attribute_or_filter.name 
    end

    def get_filter(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ? object.class.filter_by_name(attribute_or_filter) : attribute_or_filter
    end

    def datagrid_filter_class(klass)
      klass.to_s.split("::").last.underscore
    end
  end
end

ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)

