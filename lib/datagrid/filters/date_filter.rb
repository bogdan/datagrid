class Datagrid::Filters::DateFilter < Datagrid::Filters::BaseFilter
  #TODO: more smart date normalizer
  def format(value)
    return value unless value.is_a?(String)
    value.blank? ? nil : Date.parse(value)
  rescue ArgumentError
    nil
  end
end

