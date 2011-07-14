class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter

  YES = "YES"
  NO = "NO"
  VALUES = ActiveSupport::OrderedHash.new
  VALUES[YES] = YES
  VALUES[NO] = NO

  def initialize(report, attribute, options = {}, &block)
    options[:select] = VALUES.keys
    super(report, attribute, options, &block)
  end

  def apply(scope, value)
    super(scope, to_boolean(value))
  end

  def to_boolean(value)
    VALUES[value]
  end

end
