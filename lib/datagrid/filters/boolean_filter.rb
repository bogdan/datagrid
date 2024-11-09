# frozen_string_literal: true

require "datagrid/utils"

module Datagrid
  module Filters
    class BooleanFilter < Datagrid::Filters::BaseFilter
      def default_input_options
        { **super, type: "checkbox" }
      end

      def parse(value)
        Datagrid::Utils.booleanize(value)
      end
    end
  end
end
