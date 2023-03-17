class Datagrid::Filters::TextFilter < Datagrid::Filters::BaseFilter
  def parse(value)
    value.nil? ? nil : value.to_s
  end
end
