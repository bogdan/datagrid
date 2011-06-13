class Datagrid::Filters::IntegerFilter < Datagrid::Filters::BaseFilter
  def format(value)
    return nil if value.blank?
    value.to_i
  end
end

