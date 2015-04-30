require "datagrid/filters/ranged_filter"

class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::RangedFilter

  def apply(grid_object, scope, value)
    if value.is_a?(Range)
      value = value.first.beginning_of_day..value.last.end_of_day
    end
    super(grid_object, scope, value)
  end

  def parse(value)
    Datagrid::Utils.parse_date(value)
  end


  def format(value)
    if formats.any? && value
      value.strftime(formats.first)
    else
      super
    end
  end

  def default_filter_where(scope, value)
    if driver.is_timestamp?(scope, name)
      value = Datagrid::Utils.format_date_as_timestamp(value)
    end
    super(scope, value)
  end

  protected

  def formats
    Array(Datagrid.configuration.date_formats)
  end
end

