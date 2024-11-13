# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class EnumFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      # @!visibility private
      def initialize(grid, name, **options, &block)
        options[:multiple] = true if options[:checkboxes]
        super(grid, name, **options, &block)
        raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
      end

      def parse(value)
        return nil if strict && !select.include?(value)

        value
      end

      def default_input_options
        {
          **super,
          type: enum_checkboxes? ? "checkbox" : "select",
          multiple: multiple?,
          include_hidden: enum_checkboxes? ? false : nil,
        }
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
