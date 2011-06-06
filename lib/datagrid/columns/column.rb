
class Datagrid::Columns::Column

  attr_accessor :grid, :options, :block, :name

  def initialize(grid, name, options = {}, &block)
    self.grid = grid
    self.name = name
    self.options = options
    self.block = block
  end

  def value(object)
    value_for(object)
  end

  def value_for(object)
    object.instance_eval(&self.block)
  end

  def format
    self.options[:format]
  end

  def label
    self.options[:label]
  end

  def header
    self.options[:header] || 
      I18n.translate(self.name, :scope => "reports.#{self.grid}.columns", :default => self.name.to_s.humanize )
  end

  def order
    if options.has_key?(:order)
      self.options[:order]
    else
      grid.scope.column_names.include?(name.to_s) ? [grid.scope.table_name, name].join(".") : nil
    end
  end

  def desc_order
    order ? order.to_s + " DESC" : nil
  end

end
