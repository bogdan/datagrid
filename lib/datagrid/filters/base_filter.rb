require "datagrid/filters/filter_eval"

class Datagrid::Filters::BaseFilter

  attr_accessor :grid, :options, :block, :name

  def initialize(grid, name, options = {}, &block)
    self.grid = grid
    self.name = name
    self.options = options
    self.block = block
  end

  def format(value)
    raise NotImplementedError, "#format(value) suppose to be overwritten"
  end

  def apply(scope, value)
    return scope if value.nil? && !options[:allow_nil]
    return scope if value.blank? && !options[:allow_blank]
    ::Datagrid::Filters::FilterEval.new(self, scope, value).run
  end

  def format_values(value)
    if !self.multiple && value.is_a?(Array) 
      raise Datagrid::ArgumentError, "#{grid.class}.#{name} filter can not accept Array argument. Use :multiple option." 
    end
    values = Array(value)
    values.map! do |value|
      self.format(value)
    end
    self.multiple ? values : values.first
  end

  def header
    options[:header] || 
      I18n.translate(self.name, :scope => "datagrid.#{grid.param_name}.filters", :default => self.name.to_s.humanize)
  end

  def default
    default = self.options[:default]
    default.respond_to?(:call) ? default.call : default
  end

  def multiple
    self.options[:multiple]
  end
end

