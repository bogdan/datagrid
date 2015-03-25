class Datagrid::Filters::ExtendedBooleanFilter < Datagrid::Filters::EnumFilter #:nodoc: 

  YES = "YES"
  NO = "NO"

  def initialize(report, attribute, options = {}, &block)
    options[:select] = [YES, NO].map do |key, value|
      [I18n.t("datagrid.filters.xboolean.#{key.downcase}"), key]
    end
    super(report, attribute, options, &block)
  end

  def execute(value, scope, grid_object) 
    value = value.blank? ? nil : ::Datagrid::Utils.booleanize(value)
    super(value, scope, grid_object)
  end

  def parse(value)
    case
    when value == true
      YES
    when value == false
      NO
    when value.blank?
      nil
    else
      super(value)
    end
  end

end
