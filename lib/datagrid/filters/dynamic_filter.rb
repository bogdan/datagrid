require "datagrid/filters/select_options"

class Datagrid::Filters::DynamicFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::SelectOptions

  def initialize(*)
    super
    options[:select] ||= default_select
    unless options.has_key?(:include_blank)
      options[:include_blank] = false
    end
  end

  def parse_values(filter)
    field, operation, value = filter

    [field, operation, type_cast(field, value)]
  end

  def unapplicable_value?(filter)
    field, operation, value = filter
    field.blank? || operation.blank? || super(value)
  end

  def default_filter_where(driver, scope, filter)
    field, operation, value = filter
    date_conversion = value.is_a?(Date) && driver.is_timestamp?(scope, field)
    case operation
    when '='
      if date_conversion
        value = Datagrid::Utils.format_date_as_timestamp(value)
      end
      driver.where(scope, field, value)
    when '=~'
      if column_type(field) == :string
        driver.contains(scope, field, value)
      else
        driver.where(scope, field, value)
      end
    when '>='
      if date_conversion
        value = value.beginning_of_day
      end
      driver.greater_equal(scope, field, value)
    when '<='
      if date_conversion
        value = value.end_of_day
      end
      driver.less_equal(scope, field, value)
    else
      raise "unknown operation: #{operation.inspect}"
    end
  end

  def operations_select
    %w(= =~ >= <=).map do |operation|
      [I18n.t(operation, :scope => "datagrid.filters.dynamic.operations").html_safe, operation]
    end
  end

  protected

  def default_select
    proc {|grid|
      grid.driver.column_names(grid.scope).map do |name|
        # Mongodb/Rails problem:
        # '_id'.humanize returns ''
        [name.gsub(/^_/, '').humanize.strip, name]
      end
    }
  end

  def type_cast(field, value)
    type = column_type(field)
    return nil if value.blank?
    case type
    when :string
      value.to_s
    when :integer
      value.is_a?(Numeric) || value =~ /^\d/ ?  value.to_i : nil
    when :float
      value.is_a?(Numeric) || value =~ /^\d/ ?  value.to_f : nil
    when :date
      Datagrid::Utils.parse_date(value)
    when :timestamp
      Datagrid::Utils.parse_date(value)
    when :boolean
      Datagrid::Utils.booleanize(value)
    end
  end

  def column_type(field)
    grid_class.driver.normalized_column_type(grid_class.scope, field)
  end
end
