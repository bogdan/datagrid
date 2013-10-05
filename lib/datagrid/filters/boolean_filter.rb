require "datagrid/utils"
class Datagrid::Filters::BooleanFilter < Datagrid::Filters::BaseFilter #:nodoc:

  def parse(value)
    Datagrid::Utils.booleanize(value)
  end

end
