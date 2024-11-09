# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class EnumFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      self.default_input_options = { type: "select" }

      def initialize(*args)
        super
        options[:multiple] = true if enum_checkboxes?
        raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
      end

      def parse(value)
        return nil if strict && !select.include?(value)

        value
      end

      def strict
        options[:strict]
      end

      def enum_checkboxes?
        options[:checkboxes]
      end
    end
  end
end
