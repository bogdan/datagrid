# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class EnumFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      def initialize(*args)
        super
        options[:multiple] = true if checkboxes?
        raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
      end

      def parse(value)
        return nil if strict && !select.include?(value)

        value
      end

      def strict
        options[:strict]
      end

      def checkboxes?
        options[:checkboxes]
      end
    end
  end
end
