# frozen_string_literal: true

module Datagrid
  module Filters
    class FloatFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def parse(value)
        return nil if value.blank?

        value.to_f
      end
    end
  end
end
