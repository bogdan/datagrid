# @!visibility private
class Datagrid::Filters::ExtendedBooleanFilter < Datagrid::Filters::EnumFilter

  YES = "YES"
  NO = "NO"
  TRUTH_VALUES = [true, 'true', "y", "yes"]
  FALSE_VALUES = [false, 'false', "n", "no"]

  def initialize(report, attribute, options = {}, &block)
    options[:select] = -> { boolean_select }
    super(report, attribute, options, &block)
  end

  def execute(value, scope, grid_object)
    value = value.blank? ? nil : ::Datagrid::Utils.booleanize(value)
    super(value, scope, grid_object)
  end

  def parse(value)
    value = value.downcase if value.is_a?(String)
    case value
    when *TRUTH_VALUES
      YES
    when *FALSE_VALUES
      NO
    when value.blank?
      nil
    else
      super(value)
    end
  end

  protected

  def boolean_select
    [YES, NO].map do |key, value|
      [I18n.t("datagrid.filters.xboolean.#{key.downcase}"), key]
    end
  end
end
