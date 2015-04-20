require "datagrid/filters/ranged_filter"

class Datagrid::Filters::IntegerFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::RangedFilter

  def parse(value)
    return nil if value.blank?
    return value if value.is_a?(Range)
    value.to_i
  end
end

