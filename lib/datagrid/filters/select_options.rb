module Datagrid::Filters::SelectOptions

  def select(object = nil)
    unless object
      Datagrid::Utils.warn_once("#{self.class.name}#select without argument is deprecated")
    end
    select = self.options[:select]
    if select.is_a?(Symbol)
      object.send(select)
    elsif select.respond_to?(:call)
      Datagrid::Utils.apply_args(object, &select)
    else
      select
    end
  end

  def include_blank
    unless prompt
      options.has_key?(:include_blank) ? options[:include_blank] : !multiple?
    end
  end
  
  def prompt
    options.has_key?(:prompt) ? options[:prompt] : false
  end
end
