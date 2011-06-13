class Datagrid::Filters::EnumFilter < Datagrid::Filters::BaseFilter

  def initialize(*args)
    super(*args)
    raise Datagrid::ConfigurationError, ":select option not specified" unless select
  end
  def format(value)
    values = Array.new([*value])
    values.reject do |value|
      #TODO: really impelement #strict option
      self.strict && !select.include?(value)
    end
    self.multiple ? values : values.first
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

  def multiple
    self.options[:multiple]
  end
end
