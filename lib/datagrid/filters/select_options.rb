# frozen_string_literal: true

module Datagrid
  module Filters
    module SelectOptions
      def select(object)
        select = options[:select]
        if select.is_a?(Symbol)
          object.send(select)
        elsif select.respond_to?(:call)
          Datagrid::Utils.apply_args(object, &select)
        else
          select
        end
      end

      def select_values(object)
        Datagrid::Utils.select_values(select(object))
      end

      def include_blank
        return if prompt

        if options.key?(:include_blank)
          Datagrid::Utils.callable(options[:include_blank])
        else
          !multiple?
        end
      end

      def prompt
        options.key?(:prompt) ? Datagrid::Utils.callable(options[:prompt]) : false
      end
    end
  end
end
