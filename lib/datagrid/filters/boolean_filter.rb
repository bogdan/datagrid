require "datagrid/utils"
class Datagrid::Filters::BooleanFilter < Datagrid::Filters::BaseFilter

  def format(value)
    Datagrid::Utils.booleanize(value)
  end

end
