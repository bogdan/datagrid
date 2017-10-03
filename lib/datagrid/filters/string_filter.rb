class Datagrid::Filters::StringFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::RangedFilter

  def parse(value)
    value.nil? ? nil : value.to_s
  end
end
