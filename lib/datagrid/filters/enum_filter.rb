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
    select = self.options[:select]
    if select.is_a?(Symbol)
      object.send(select)
    elsif select.respond_to?(:call)
      select.arity == 1 ? select.call(object) : select.call
    else
      select
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
