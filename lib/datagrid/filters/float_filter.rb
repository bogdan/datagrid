class Datagrid::Filters::FloatFilter < Datagrid::Filters::BaseFilter

  include RangedFilter

  def parse(value)
    return nil if value.blank?
    value.to_f
  end
end
