module Datagrid
  module FormBuilder

    def report_filter(filter_or_attribute, options = {})
      filter = get_filter(filter_or_attribute)
      options[:class] ||= " "
      options[:class] += " #{filter.attribute} #{filter.type}"
      self.send(:"report_#{filter.class.to_s.underscore.split('/').last}", filter, options)
    end

    protected
    def report_boolean_enum_filter(attribute_or_filter, options = {})
      report_enum_filter(attribute_or_filter, options)
    end

    def report_boolean_filter(attribute_or_filter, options = {})
      check_box(get_attribute(attribute_or_filter), options)
    end

    def report_date_filter(attribute_or_filter, options = {})
      attribute = get_attribute(attribute_or_filter)
      text_field(attribute, options)
    end

    def report_default_filter(attribute_or_filter, options = {})
      text_field get_attribute(attribute_or_filter), options
    end

    def report_enum_filter(attribute_or_filter, options = {})
      filter = get_filter(attribute_or_filter)
      select filter.attribute, filter.select_for(self.object) || [], {:include_blank => filter.include_blank}, {:multiple => filter.multiple}.merge(options)
    end

    def report_integer_filter(attribute_or_filter, options = {})
      text_field get_attribute(attribute_or_filter), options
    end

    def get_attribute(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ?  attribute_or_filter : attribute_or_filter.attribute 
    end

    def get_filter(attribute_or_filter)
      attribute_or_filter.is_a?(Symbol) ? object.class.filter_by_name(attribute_or_filter) : attribute_or_filter
    end

  end
end

