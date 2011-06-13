class Datagrid::Filters::BooleanFilter < Datagrid::Filters::BaseFilter

  def format(value)
    [true, 1, "1", "true", "yes", "on"].include?(value)
  end

end
