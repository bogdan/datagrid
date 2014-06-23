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

    def call_data
      data_block.call
    end

    def call_html(context)
      context.instance_eval(&html_block)
    end
  end

  attr_accessor :grid_class, :options, :data_block, :name, :html_block, :query

  def initialize(grid_class, name, query, options = {}, &block)
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
    self.query = query
    options[:if] = convert_option_to_proc(options[:if])
    options[:unless] = convert_option_to_proc(options[:unless])
  end

  def data_value(model, grid)
    raise "no data value for #{name} column" unless data?
    result = generic_value(model,grid)
    result.is_a?(ResponseFormat) ? result.call_data : result
  end


  def label
    self.options[:label]
  end

  def header
    self.options[:header] ||
      I18n.translate(self.name, :scope => "datagrid.#{self.grid_class.param_name}.columns", :default => self.grid_class.scope.human_attribute_name(self.name))
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

  def enabled?(grid)
    (!options[:if] || (options[:if] && options[:if].call(grid))) && !options[:unless] || (options[:unless] && !options[:unless].call(grid))
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
      result.is_a?(ResponseFormat) ? result.call_html(context) : result
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
    unless enabled?(grid)
      raise Datagrid::ColumnUnavailableError, "Column #{name} disabled for #{grid.inspect}"
    end
    if self.data_block.arity >= 1
      Datagrid::Utils.apply_args(model, grid, grid.data_row(model), &data_block)
    else
      model.instance_eval(&self.data_block)
    end
  end

  private
  def convert_option_to_proc(option)
    if option.is_a?(Proc)
      option
    elsif option
      proc {|object| object.send(option.to_sym) }
    end
  end
end
