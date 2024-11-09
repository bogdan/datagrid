# frozen_string_literal: true

# @!visibility private
module Datagrid
  module Filters
    class FloatFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def default_input_options
        { **super, type: "number", step: "any" }
      end

      def parse(value)
        return nil if value.blank?

        value.to_f
      end
    end
  end
end
