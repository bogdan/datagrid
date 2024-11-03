# frozen_string_literal: true

require "datagrid/filters/select_options"

module Datagrid
  module Filters
    class EnumFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::SelectOptions

      def initialize(*args)
        super(*args)
        options[:multiple] = true if checkboxes?
        raise Datagrid::ConfigurationError, ":select option not specified" unless options[:select]
      end

      def parse(value)
        return nil if strict && !select.include?(value)

        value
      end

      def default_html_classes
        res = super
        res.push("checkboxes") if checkboxes?
        res
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
