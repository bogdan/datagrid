# frozen_string_literal: true

require "datagrid/utils"
# @!visibility private
module Datagrid
  module Filters
    class BooleanFilter < Datagrid::Filters::BaseFilter
      def parse(value)
        Datagrid::Utils.booleanize(value)
      end
    end
  end
end
