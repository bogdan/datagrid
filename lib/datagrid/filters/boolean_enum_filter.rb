class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter

  YES = "YES"
  NO = "NO"
  VALUES = ActiveSupport::OrderedHash.new
  VALUES[YES] = true
  VALUES[NO] = false

  def initialize(report, attribute, options = {}, &block)
    options[:select] = VALUES.keys
    options[:allow_blank] = true
    options[:allow_nil] = false
    super(report, attribute, options, &block)
  end

  def apply(grid_object, scope, value)
    super(grid_object, scope, to_boolean(value))
  end

  def to_boolean(value)
    value.blank? ? nil : VALUES[value]
  end

end
