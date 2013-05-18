require "datagrid/utils"
class Datagrid::Filters::BooleanFilter < Datagrid::Filters::BaseFilter

  def parse(value)
    Datagrid::Utils.booleanize(value)
  end

end
