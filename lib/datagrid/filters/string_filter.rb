class Datagrid::Filters::StringFilter < Datagrid::Filters::BaseFilter
  def format(value)
    value.nil? ? nil : value.to_s
  end
end
