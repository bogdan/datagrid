class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter

  YES = "YES"
  NO = "NO"
  VALUES = {YES => true, NO => false}

  def initialize(report, attribute, options = {}, &block)
    options[:allow_blank] = true unless options.has_key?(:allow_blank)
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
