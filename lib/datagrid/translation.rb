require "action_view/helpers"

module Datagrid
  module Translation
    include ActionView::Helpers::TranslationHelper

    def translate_from_namespace(namespace, grid_class, key)
      deprecated_namespace = :"datagrid.#{grid_class.param_name}.#{namespace}.#{key}"

      Datagrid::Utils.warn_once(
        "Deprecated translation namespace. Use 'datagrid.#{grid_class.model_name.i18n_key}' instead"
      ) if I18n.exists? deprecated_namespace

      lookups = [
        :"datagrid.#{grid_class.model_name.i18n_key}.#{namespace}.#{key}",
        deprecated_namespace,
        key.to_s.humanize
      ]
      t(lookups.shift, default: lookups).presence
    end

  end
end
