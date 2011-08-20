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
    option = self.options[:select]
    option.respond_to?(:call) ? option.call : option
  end

  def include_blank
    self.options.has_key?(:include_blank) ? options[:include_blank] : true unless self.prompt
  end
  
  def prompt
    self.options.has_key?(:prompt) ? options[:prompt] : false
  end

  def strict
    self.options[:strict]
  end

end
