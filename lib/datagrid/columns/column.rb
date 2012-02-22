class Datagrid::Columns::Column

  attr_accessor :grid, :options, :block, :name

  def initialize(grid, name, options = {}, &block)
    self.grid = grid
    self.name = name.to_sym
    self.options = options
    self.block = block
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
      self.grid.scope.klass.human_attribute_name(self.name)
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
    !! self.options[:html]
  end
  

end
