require "datagrid/filters/select_options"

class Datagrid::Filters::DynamicFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::SelectOptions

  AVAILABLE_OPERATIONS = %w(= =~ >= <=)

  def initialize(*)
    super
    options[:select] ||= default_select
    options[:operations] ||= AVAILABLE_OPERATIONS
    unless options.has_key?(:include_blank)
      options[:include_blank] = false
    end
  end

  def parse_values(filter)
    field, operation, value = filter

    [field, operation, type_cast(field, value)]
  end

  def unapplicable_value?(filter)
    _, _, value = filter
    super(value)
  end

  def default_filter_where(scope, filter)
    field, operation, value = filter
    date_conversion = value.is_a?(Date) && driver.is_timestamp?(scope, field)

    return scope if field.blank? || operation.blank?
    unless operations.include?(operation)
      raise Datagrid::FilteringError, "Unknown operation: #{operation.inspect}. Available operations: #{operations.join(' ')}"
    end
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
        if date_conversion
          value = Datagrid::Utils.format_date_as_timestamp(value)
        end
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
      raise Datagrid::FilteringError, "Unknown operation: #{operation.inspect}. Use filter block argument to implement operation"
    end
  end

  def operations
    options[:operations]
  end

  def operations_select
    operations.map do |operation|
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
    when nil
      value
    else
      raise NotImplementedError, "unknown column type: #{type.inspect}"
    end
  end

  def column_type(field)
    grid_class.driver.normalized_column_type(grid_class.scope, field)
  end
end
