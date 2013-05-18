class Datagrid::Filters::StringFilter < Datagrid::Filters::BaseFilter
  def parse(value)
    value.nil? ? nil : value.to_s
  end
end
