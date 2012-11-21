require "datagrid/filters/ranged_filter"

class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter

  include RangedFilter

  def apply(grid_object, scope, value)
    if value.is_a?(Range)
      value = value.first.beginning_of_day..value.last.end_of_day
    end
    super(grid_object, scope, value)
  end

  def format(value)
    return nil if value.blank?
    return value if value.is_a?(Range)
    return value.to_date if value.respond_to?(:to_date)
    return value unless value.is_a?(String)
    #TODO: more smart date normalizer
    Date.parse(value)
  rescue ArgumentError
    nil
  end

end

