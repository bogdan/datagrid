class Datagrid::FilteringError < StandardError
end

class Datagrid::Filters::BaseFilter #:nodoc:

  attr_accessor :grid_class, :options, :block, :name

  def initialize(grid_class, name, options = {}, &block)
    self.grid_class = grid_class
    self.name = name
    self.options = options
    self.block = block || default_filter_block
  end

  def parse(value)
    raise NotImplementedError, "#parse(value) suppose to be overwritten"
  end

  def unapplicable_value?(value)
    value.nil? ? !allow_nil? : value.blank? && !allow_blank?
  end

  def apply(grid_object, scope, value)
    return scope if unapplicable_value?(value)

    result = execute(value, scope, grid_object)
    return scope unless result
    unless grid_object.driver.match?(result)
      raise Datagrid::FilteringError, "Can not apply #{name.inspect} filter: result #{result.inspect} no longer match #{grid_object.driver.class}."
    end
    result
  end

  def parse_values(value)
    if multiple?
      return nil if value.nil?
      normalize_multiple_value(value).map do |v|
        parse(v)
      end
    elsif value.is_a?(Array)
      raise Datagrid::ArgumentError, "#{grid_class}##{name} filter can not accept Array argument. Use :multiple option."
    else
      parse(value)
    end
  end

  def separator
    options[:multiple].is_a?(String) ? options[:multiple] : default_separator
  end

  def header
    if header = options[:header] 
      callable(header)
    else
      Datagrid::Utils.translate_from_namespace(:filters, grid_class, name)
    end
  end

  def default(object = nil)
    unless object
      Datagrid::Utils.warn_once("#{self.class.name}#default without argument is deprecated")
    end
    default = self.options[:default]
    if default.is_a?(Symbol)
      if object.respond_to?(default)
        object.send(default)
      else
        Datagrid::Utils.warn_once(":default as a Symbol is now treated as a method name. Use String instead or -> { default } if you really want default value to be a Symbol but not a String.")
        default
      end
    elsif default.respond_to?(:call) 
      Datagrid::Utils.apply_args(object, &default)
    else
      default
    end
  end

  def multiple
    Datagrid::Utils.warn_once("Filter#multiple method is deprecated. Use Filter#multiple? instead")
    multiple?
  end

  def multiple?
    self.options[:multiple]
  end

  def allow_nil?
    options.has_key?(:allow_nil) ? options[:allow_nil] : options[:allow_blank]
  end

  def allow_blank?
    options[:allow_blank]
  end

  def form_builder_helper_name
    self.class.form_builder_helper_name
  end

  def self.form_builder_helper_name
    :"datagrid_#{self.to_s.demodulize.underscore}"
  end

  def default_filter_block
    filter = self
    lambda do |value, scope, grid|
      filter.default_filter(value, scope, grid)
    end
  end

  def supports_range?
    self.class.ancestors.include?(::Datagrid::Filters::RangedFilter)
  end

  def format(value)
    value.nil? ? nil : value.to_s
  end

  def dummy?
    options[:dummy]
  end

  def type
    Datagrid::Filters::FILTER_TYPES.each do |type, klass|
      if is_a?(klass)
        return type
      end
    end
    raise "wtf is #{inspect}"
  end

  protected

  def default_filter_where(scope, value)
    driver.where(scope, name, value)
  end

  def execute(value, scope, grid_object)
    if block.arity == 1
      scope.instance_exec(value, &block)
    else
      Datagrid::Utils.apply_args(value, scope, grid_object, &block)
    end
  end

  def normalize_multiple_value(value)
    case value
    when String
      #TODO: write tests and doc
      value.split(separator)
    when Array
      value
    else
      Array.wrap(value)
    end
  end

  def default_separator
    ','
  end

  def callable(value)
    value.respond_to?(:call) ? value.call : value
  end

  def driver
    grid_class.driver
  end

  def default_filter(value, scope, grid)
    return nil if dummy?
    if !driver.has_column?(scope, name) && driver.to_scope(scope).respond_to?(name)
      driver.to_scope(scope).send(name, value)
    else
      default_filter_where(scope, value)
    end
  end

end

