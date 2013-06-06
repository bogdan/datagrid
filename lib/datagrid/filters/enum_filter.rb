class Datagrid::Filters::EnumFilter < Datagrid::Filters::BaseFilter

  def initialize(*args)
    super(*args)
    raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
  end

  def parse(value)
    return nil if self.strict && !select.include?(value)
    value
  end

  def select(object = nil)
    option = self.options[:select]
    if option.respond_to?(:call)
      option.arity == 1 ? option.call(object) : option.call
    else
      option
    end
  end

  def include_blank
    unless self.prompt
      self.options.has_key?(:include_blank) ? options[:include_blank] : !multiple
    end
  end
  
  def prompt
    self.options.has_key?(:prompt) ? options[:prompt] : false
  end

  def strict
    self.options[:strict]
  end

end
