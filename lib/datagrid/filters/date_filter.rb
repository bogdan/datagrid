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
        if value.is_a?(Range)
          value = value.begin&.beginning_of_day..value.end&.end_of_day
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

      def default_filter_where(scope, value)
        if driver.is_timestamp?(scope, name)
          value = Datagrid::Utils.format_date_as_timestamp(value)
        end
        super
      end

      protected

      def formats
        Array(Datagrid.configuration.date_formats)
      end
    end
  end
end
