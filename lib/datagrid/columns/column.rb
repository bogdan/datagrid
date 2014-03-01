class Datagrid::Columns::Column

  class ResponseFormat # :nodoc:

    attr_accessor :data_block, :html_block

    def initialize
      yield(self)
    end

    def data(&block)
      self.data_block = block
    end

    def html(&block)
      self.html_block = block
    end

    def data_value
      data_block.call
    end

    def html_value(context)
      context.instance_eval(&html_block)
    end
  end

  attr_accessor :grid_class, :options, :data_block, :name, :html_block

  def initialize(grid_class, name, options = {}, &block)
    self.grid_class = grid_class
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
    raise "no data value for #{name} column" unless data?
    result = generic_value(model,grid)
    result.is_a?(ResponseFormat) ? result.data_value : result
  end


  def label
    self.options[:label]
  end

  def header
    self.options[:header] || 
      I18n.translate(self.name, :scope => "datagrid.#{self.grid_class.param_name}.columns", :default => self.name.to_s.humanize )
  end

  def order
    if options.has_key?(:order) && options[:order] != true
      self.options[:order]
    else
      grid_class.driver.default_order(grid_class.scope, name)
    end
  end

  def supports_order?
    order || order_by_value?
  end

  def order_by_value(model, grid)
    if options[:order_by_value] == true
      data_value(model, grid)
    else
      Datagrid::Utils.apply_args(model, grid, &options[:order_by_value])
    end
  end

  def order_by_value?
    !! options[:order_by_value]
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
  
  def mandatory?
    !! options[:mandatory]
  end

  def select
    options[:select]
  end

  def inspect
    "#<Datagird::Columns::Column #{grid_class}##{name} #{options.inspect}>"
  end

  def to_s
    header
  end

  def html_value(context, asset, grid)
    if html? && html_block
      value_from_html_block(context, asset, grid)
    else
      result = generic_value(asset,grid)
      result.is_a?(ResponseFormat) ? result.html_value(context) : result
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

  def generic_value(model, grid)
    if self.data_block.arity >= 1
      Datagrid::Utils.apply_args(model, grid, &data_block)
    else
      model.instance_eval(&self.data_block)
    end
  end

end
