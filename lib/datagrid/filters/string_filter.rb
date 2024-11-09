# frozen_string_literal: true

module Datagrid
  module Filters
    class StringFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def parse(value)
        value&.to_s
      end
    end
  end
end
