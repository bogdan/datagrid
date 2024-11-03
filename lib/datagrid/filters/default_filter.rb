# frozen_string_literal: true

module Datagrid
  module Filters
    class DefaultFilter < Datagrid::Filters::BaseFilter
      def parse(value)
        value
      end
    end
  end
end
