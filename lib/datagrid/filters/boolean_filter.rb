# frozen_string_literal: true

require "datagrid/utils"

module Datagrid
  module Filters
    class BooleanFilter < Datagrid::Filters::BaseFilter

      # @!visibility private
      def initialize(grid, name, **opts)
        super(grid, name, **opts)
        options[:default] ||= false
      end

      def default_input_options
        { **super, type: "checkbox" }
      end

      def parse(value)
        Datagrid::Utils.booleanize(value)
      end
    end
  end
end
