class Datagrid::Filters::FloatFilter < Datagrid::Filters::BaseFilter
  def format(value)
    return nil if value.blank?
    value.to_f
  end
end
