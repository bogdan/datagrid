class Datagrid::Filters::EnumFilter < Datagrid::Filters::BaseFilter

  def initialize(*args)
    super(*args)
    raise Datagrid::ConfigurationError, ":select option not specified" unless select
  end

  def format(value)
    return nil if self.strict && !select.include?(value)
    value
  end

  def select
    self.options[:select]
  end


  def include_blank
    self.options.has_key?(:include_blank) ? options[:include_blank] : true
  end

  def strict
    self.options[:strict]
  end

end
