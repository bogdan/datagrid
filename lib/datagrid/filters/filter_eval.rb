# ActiveRecord is a little brain fuck.
# We can not call instance_eval on ActiveRecord::Relation class
# because it will automatically convert it to an array because #instance_eval
# is not included in the method list that do not cause force result loading
# That is why we need thi helper class
class Datagrid::Filters::FilterEval

  attr_accessor :filter, :scope, :value

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
