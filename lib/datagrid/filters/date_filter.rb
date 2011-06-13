class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter
  #TODO: more smart date normalizer
  def format(value)
    return nil if value.blank?
    return value.to_date if value.respond_to?(:to_date)
    return value unless value.is_a?(String)
    Date.parse(value)
  rescue ArgumentError
    nil
  end
end

