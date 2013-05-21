require "datagrid/filters/ranged_filter"

class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter

  include RangedFilter

  def apply(grid_object, scope, value)
    if value.is_a?(Range)
      value = value.first.beginning_of_day..value.last.end_of_day
    end
    super(grid_object, scope, value)
  end

  def parse(value)
    return nil if value.blank?
    return value if value.is_a?(Range)
    if value.is_a?(String)
      formats.each do |format|
        begin
          return Date.strptime(value, format)
        rescue ArgumentError
        end
      end
    end
    return value.to_date if value.respond_to?(:to_date)
    return value unless value.is_a?(String)
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def formats
    Array(Datagrid.configuration.date_formats)
  end

  def format(value)
    if formats.any?
      value.strftime(formats.first)
    else
      super
    end
  end

  def default_filter_where(driver, scope, value)
    if driver.is_timestamp?(scope, name)
      value = format_value_timestamp(value)
    end
    super(driver, scope, value)
  end

  protected
  def format_value_timestamp(value)
    if !value
      value
    elsif (range? && value.is_a?(Array))
      [value.first.try(:beginning_of_day), value.last.try(:end_of_day)]
    elsif value.is_a?(Range)
      (value.first.beginning_of_day..value.last.end_of_day)
    else
      value.beginning_of_day..value.end_of_day
    end
  end

end

