# frozen_string_literal: true

require "datagrid/utils"

module Datagrid
  module Filters
    class BooleanFilter < Datagrid::Filters::BaseFilter
      self.default_input_options = { type: "checkbox" }

      def parse(value)
        Datagrid::Utils.booleanize(value)
      end
    end
  end
end
