class Datagrid::Filters::FilterEval

  def initialize(filter, scope, value)
    @filter = filter
    @scope = scope
    @value = value
  end

  def run
    instance_exec @value, &(@filter.block)
  end

  def method_missing(meth, *args, &blk)
    if @scope.respond_to?(meth)
      @scope.send(meth, *args, &blk)
    else
      super(meth, *args, &blk)
    end
  end
end
