class Datagrid::Columns::Column

  attr_accessor :grid, :options, :block, :name, :html_block

  def initialize(grid, name, options = {}, &block)
    self.grid = grid
    self.name = name.to_sym
    self.options = options
    if options[:html] == true
      self.html_block = block
    else
      if options[:html].is_a? Proc
        self.html_block = options[:html]
      end
      self.block = block
    end
    if format
      ::Datagrid::Utils.warn_once(":format column option is deprecated. Use :url or :html option instead.")
    end
  end

  def value(model, grid)
    value_for(model, grid)
  end

  def value_for(model, grid)
    if self.block.arity == 1
      self.block.call(model)
    elsif self.block.arity == 2
      self.block.call(model, grid)
    else
      model.instance_eval(&self.block)
    end
  end

  def format
    self.options[:format]
  end

  def label
    self.options[:label]
  end

  def header
    self.options[:header] || 
      I18n.translate(self.name, :scope => "datagrid.#{self.grid.param_name}.columns", :default => self.name.to_s.humanize )
  end

  def order
    if options.has_key?(:order)
      self.options[:order]
    else
      grid.driver.default_order(grid.scope, name)
    end
  end

  def order_desc
    return nil unless order
    self.options[:order_desc]  
  end

  def html?
    self.html_block != nil
  end
  
  def data?
    self.block != nil
  end

end
