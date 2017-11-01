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

    def to_s
      call_data.to_s
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
  end

  def data_value(model, grid)
    # backward compatibility method
    grid.data_value(name, model)
  end


  def label
    self.options[:label]
  end

  def header
    if header = options[:header]
      Datagrid::Utils.callable(header)
    else
      Datagrid::Utils.translate_from_namespace(:columns, grid_class, name)
    end
  end

  def order
    if options.has_key?(:order) && options[:order] != true
      self.options[:order]
    else
      driver.default_order(grid_class.scope, name)
    end
  end

  def supports_order?
    order || order_by_value?
  end

  def order_by_value(model, grid)
    if options[:order_by_value] == true
      grid.data_value(self, model)
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
    ::Datagrid::Utils.process_availability(grid, options[:if], options[:unless])
  end

  def inspect
    "#<#{self.class} #{grid_class}##{name} #{options.inspect}>"
  end

  def to_s
    header
  end

  def html_value(context, asset, grid)
    grid.html_value(name, context, asset)
  end


  def block
    Datagrid::Utils.warn_once("Datagrid::Columns::Column#block is deprecated. Use #html_block or #data_block instead")
    data_block
  end

  def generic_value(model, grid)
    grid.generic_value(self, model)
  end

  def append_preload(scope)
    return scope unless preload
    if preload.respond_to?(:call)
      return scope unless preload
      if preload.arity == 1
        preload.call(scope)
      else
        scope.instance_exec(&preload)
      end
    else
      driver.default_preload(scope, preload)
    end
  end

  def preload
    preload = options[:preload]

    if preload == true && driver.can_preload?(driver.to_scope(grid_class.scope), name)
      name
    else
      preload
    end

  end

  def driver
    grid_class.driver
  end
end
