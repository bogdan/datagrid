# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class EnumFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      # @!visibility private
      def initialize(grid, name, **options, &block)
        options[:multiple] = true if options[:checkboxes]
        super
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

      def label_options
        if enum_checkboxes?
          # Each checkbox has its own label
          # The main label has no specific input to focus
          # See app/views/datagrid/_enum_checkboxes.html.erb
          {for: nil, **super}
        else
          super
        end
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
