require "datagrid/filters/filter_eval"

class Datagrid::Filters::BaseFilter

  attr_accessor :grid, :options, :block, :attribute

  def initialize(grid, attribute, options = {}, &block)
    self.grid = grid
    self.attribute = attribute
    self.options = options
    self.block = block
  end

  def apply(scope, value)
    return scope if value.nil? && !options[:allow_nil]
    return scope if value.blank? && !options[:allow_blank]
    ::Datagrid::Filters::FilterEval.new(self, scope, value).run
  end

  def format(value)
    raise NotImplementedError, "#format(value) suppose to be overwritten"
  end

  def header
    I18n.translate(self.attribute, :scope => "datagrid.#{grid.class.to_s.underscore.split("/").last}.filters", :default => self.attribute.to_s.humanize)
  end

  def default
    self.options[:default]
  end

end

