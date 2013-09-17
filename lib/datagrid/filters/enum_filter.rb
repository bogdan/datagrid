require "datagrid/filters/select_options"

class Datagrid::Filters::EnumFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::SelectOptions

  def initialize(*args)
    super(*args)
    raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
  end

  def parse(value)
    return nil if self.strict && !select.include?(value)
    value
  end

  def strict
    self.options[:strict]
  end

end
