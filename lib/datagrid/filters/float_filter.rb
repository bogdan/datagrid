class Datagrid::Filters::FloatFilter < Datagrid::Filters::BaseFilter
  def parse(value)
    return nil if value.blank?
    value.to_f
  end
end
