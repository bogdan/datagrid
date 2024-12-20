# frozen_string_literal: true

module Datagrid
  module Filters
    class ExtendedBooleanFilter < Datagrid::Filters::EnumFilter
      YES = "YES"
      NO = "NO"
      TRUTH_VALUES = [true, "true", "y", "yes"].freeze
      FALSE_VALUES = [false, "false", "n", "no"].freeze

      def initialize(*args, **options)
        options[:select] = -> { boolean_select }
        super
      end

      def execute(value, scope, grid_object)
        value = value.blank? ? nil : ::Datagrid::Utils.booleanize(value)
        super
      end

      def default_input_options
        { **super, type: "select" }
      end

      def parse(value)
        value = value.downcase if value.is_a?(String)
        case value
        when *TRUTH_VALUES
          YES
        when *FALSE_VALUES
          NO
        when value.blank?
          nil
        else
          super
        end
      end

      protected

      def boolean_select
        [YES, NO].map do |key, _value|
          [I18n.t("datagrid.filters.xboolean.#{key.downcase}"), key]
        end
      end
    end
  end
end
