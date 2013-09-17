class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter

  YES = "YES"
  NO = "NO"

  def initialize(report, attribute, options = {}, &block)
    options[:select] = [YES, NO].map do |key, value|
      [I18n.t("datagrid.filters.eboolean.#{key.downcase}"), key]
    end
    super(report, attribute, options, &block)
  end

  def apply(grid_object, scope, value)
    super(grid_object, scope, value)
  end

  def to_boolean(value)
    #TODO decide what to do with conversion
  end

end
