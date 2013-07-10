class Datagrid::Columns::Column

  attr_accessor :grid, :options, :data_block, :name, :html_block

  def initialize(grid, name, options = {}, &block)
    self.grid = grid
    self.name = name.to_sym
    self.options = options
    if options[:html] == true
      self.html_block = block
    else
      self.data_block = block

      if options[:html].is_a? Proc
        self.html_block = options[:html]
      elsif options[:html] != false
        column = self
        self.html_block = proc {|value, model|
          column.value_for(model, column.grid)
        }
      end
    end
    if format
      ::Datagrid::Utils.warn_once(":format column option is deprecated. Use :url or :html option instead.")
    end
  end

  def value(model, grid)
    value_for(model, grid)
  end

  def value_for(model, grid)
    if self.data_block.arity == 1
      self.data_block.call(model)
    elsif self.data_block.arity == 2
      self.data_block.call(model, grid)
    else
      model.instance_eval(&self.data_block)
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
    self.data_block != nil
  end

  def block
    Datagrid::Utils.warn_once("Datagrid::Columns::Column#block is deprecated. Use #html_block or #data_block instead")
    data_block
  end

end
