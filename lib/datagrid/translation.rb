require "action_view/helpers"

module Datagrid
  module Translation

    def translate_from_namespace(namespace, grid_class, key)
      deprecated_key = :"datagrid.#{grid_class.param_name}.#{namespace}.#{key}"
      live_key = :"datagrid.#{grid_class.model_name.i18n_key}.#{namespace}.#{key}"
      i18n_key = grid_class.model_name.i18n_key.to_s

      if grid_class.param_name != i18n_key && I18n.exists?(deprecated_key)
        Datagrid::Utils.warn_once(
          "Deprecated translation namespace. Use 'datagrid.#{i18n_key}' instead"
        )
        return I18n.t(deprecated_key)
      end
      I18n.t(live_key, default: key.to_s.humanize).presence
    end

  end
end
