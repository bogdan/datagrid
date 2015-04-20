require "datagrid/filters/ranged_filter"

class Datagrid::Filters::DateTimeFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::RangedFilter

  def parse(value)
    Datagrid::Utils.parse_datetime(value)
  end

  def format(value)
    if formats.any? && value
      value.strftime(formats.first)
    else
      super
    end
  end

  protected

  def formats
    Array(Datagrid.configuration.datetime_formats)
  end
end

