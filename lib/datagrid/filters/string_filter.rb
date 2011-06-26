class Datagrid::Filters::StringFilter < Datagrid::Filters::BaseFilter
  def format(value)
    value.to_s
  end
end
