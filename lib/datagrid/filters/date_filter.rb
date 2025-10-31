# frozen_string_literal: true

require "datagrid/filters/ranged_filter"

module Datagrid
  module Filters
    class DateFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def default_input_options
        { **super, type: "date" }
      end

      def apply(grid_object, scope, value)
        if !dummy? && grid_object.driver.timestamp_column?(scope, name)
          value = Datagrid::Utils.format_date_as_timestamp(value)
        end
        super
      end

      def parse(value)
        Datagrid::Utils.parse_date(value)
      end

      def format(value)
        if formats.any? && value
          value.strftime(formats.first)
        else
          super
        end
      end

      protected

      def formats
        Array(Datagrid.configuration.date_formats)
      end
    end
  end
end
