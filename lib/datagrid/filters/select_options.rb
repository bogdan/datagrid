module Datagrid::Filters::SelectOptions
  def select(object)
    select = self.options[:select]
    if select.is_a?(Symbol)
      object.send(select)
    elsif select.respond_to?(:call)
      Datagrid::Utils.apply_args(object, &select)
    else
      select
    end
  end

  def select_values(object)
    options = select(object)
    groups_used = grouped_choices?(options)
    options.map do |option|
      if groups_used
        option[1].map {|o| option_text_and_value(o)}
      else
        option_text_and_value(option)
      end
    end.map(&:last)
  end

  def include_blank
    unless prompt
      options.has_key?(:include_blank) ?
        Datagrid::Utils.callable(options[:include_blank]) : !multiple?
    end
  end

  def prompt
    options.has_key?(:prompt) ? Datagrid::Utils.callable(options[:prompt]) : false
  end

  protected

  # Rails built-in method:
  # https://github.com/rails/rails/blob/94e80269e36caf7b2d22a7ab68e6898d3a824122/actionview/lib/action_view/helpers/form_options_helper.rb#L789
  # Code reuse is difficult, so it is easier to duplicate it
  def option_text_and_value(option)
    # Options are [text, value] pairs or strings used for both.
    if !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
      option = option.reject { |e| Hash === e } if Array === option
      [option.first, option.last]
    else
      [option, option]
    end
  end

  # Rails built-in method:
  # https://github.com/rails/rails/blob/f95c0b7e96eb36bc3efc0c5beffbb9e84ea664e4/actionview/lib/action_view/helpers/tags/select.rb#L36
  # Code reuse is difficult, so it is easier to duplicate it
  def grouped_choices?(choices)
    !choices.blank? && choices.first.respond_to?(:last) && Array === choices.first.last
  end
end
