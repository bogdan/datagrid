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
      end
    end
  end

  def data_value(model, grid)
    if self.data_block.arity == 1
      self.data_block.call(model)
    elsif self.data_block.arity == 2
      self.data_block.call(model, grid)
    else
      model.instance_eval(&self.data_block)
    end
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
    options[:html] != false
  end
  
  def data?
    self.data_block != nil
  end

  def html_value(context, asset, grid)
    if html? && html_block
      value_from_html_block(context, asset, grid)
    else
      data_value(asset,grid)
    end
  end


  def value_from_html_block(context, asset, grid)
    args = []
    remaining_arity = html_block.arity

    if data?
      args << data_value(asset,grid)
      remaining_arity -= 1
    end

    args << asset if remaining_arity > 0
    args << grid if remaining_arity > 1

    return context.instance_exec(*args, &html_block)
  end

  def block
    Datagrid::Utils.warn_once("Datagrid::Columns::Column#block is deprecated. Use #html_block or #data_block instead")
    data_block
  end

end
