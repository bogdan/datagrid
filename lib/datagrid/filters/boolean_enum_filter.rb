class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter #:nodoc:

  YES = "YES"
  NO = "NO"

  def initialize(report, attribute, options = {}, &block)
    options[:select] = [YES, NO].map do |key, value|
      [I18n.t("datagrid.filters.eboolean.#{key.downcase}"), key]
    end
    super(report, attribute, options, &block)
  end

end
