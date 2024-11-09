# frozen_string_literal: true

require "datagrid/filters/ranged_filter"

module Datagrid
  module Filters
    class DateTimeFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      self.default_input_options = { type: "datetime-local" }

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
