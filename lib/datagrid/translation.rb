require "action_view/helpers"

module Datagrid
  module Translation
    include ActionView::Helpers::TranslationHelper

    def translate_from_namespace(namespace, grid_class, key)
      deprecated_translation_key = :"#{grid_class.param_name}.#{namespace}.#{key}"

      if grid_class.name.include?("::") && I18n.exists?(deprecated_translation_key)
        Datagrid::Utils.warn_once(
          "Deprecated translation namespace. Use 'datagrid.#{grid_class.model_name.i18n_key}' instead"
        )
      end

      lookups = [
        :"#{grid_class.model_name.i18n_key}.#{namespace}.#{key}",
        deprecated_translation_key,
        key.to_s.humanize
      ]
      t(lookups.shift, scope: "datagrid", default: lookups).presence
    end

  end
end
