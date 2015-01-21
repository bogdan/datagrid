class Datagrid::Filters::BooleanEnumFilter < Datagrid::Filters::EnumFilter #:nodoc:

  YES = "YES"
  NO = "NO"

  def initialize(report, attribute, options = {}, &block)
    options[:select] = [YES, NO].map do |key, value|
      [I18n.t("datagrid.filters.eboolean.#{key.downcase}", :default => key.downcase.capitalize), key]
    end
    super(report, attribute, options, &block)
  end


  def checkbox_id(value)
    [object_name, name, value].join('_').underscore 
  end
end
