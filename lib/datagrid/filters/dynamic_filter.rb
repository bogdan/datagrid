require "datagrid/filters/select_options"

class Datagrid::Filters::DynamicFilter < Datagrid::Filters::BaseFilter

  include Datagrid::Filters::SelectOptions

  def initialize(*)
    super
    options[:multiple] = true
    options[:select] ||= default_select
  end

  def parse(value)
    value
  end

  def unapplicable_value?(filter)
    field, operation, value = filter
    field.blank? || operation.blank? || super(value)
  end

  def default_filter_where(driver, scope, filter)
    field, operation, value = filter
    driver.to_scope(scope)
    case operation
    when '='
      driver.where(scope, field, value)
    when '=~'
      driver.contains(scope, field, value)
    when '>='
      driver.greater_equal(scope, field, value)
    when '<='
      driver.less_equal(scope, field, value)
    else
      raise "unknown operation: #{operation.inspect}"
    end
  end

  def operations_select
    %w(= =~ >= <=).map do |operation|
      I18n.t(operation, :scope => "datagrid.filters.dynamic.operations")
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

end
