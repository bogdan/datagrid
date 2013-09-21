require "datagrid/filters/select_options"

class Datagrid::Filters::EnumFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::SelectOptions

  def initialize(*args)
    super(*args)
    if checkboxes?
      options[:multiple] = true
    end
    raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
  end

  def parse(value)
    return nil if self.strict && !select.include?(value)
    value
  end

  def strict
    options[:strict]
  end

  def checkboxes?
    options[:checkboxes]
  end

end
