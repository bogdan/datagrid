# frozen_string_literal: true

require "datagrid/filters/ranged_filter"

module Datagrid
  module Filters
    class DateTimeFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def default_input_options
        { **super, type: "datetime-local" }
      end

      def parse(value)
        Datagrid::Utils.parse_datetime(value)
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
        Array(Datagrid.configuration.datetime_formats)
      end
    end
  end
end
