# frozen_string_literal: true

require "datagrid/filters/ranged_filter"

module Datagrid
  module Filters
    class IntegerFilter < Datagrid::Filters::BaseFilter
      include Datagrid::Filters::RangedFilter

      def default_input_options
        { **super, type: "number", step: "1" }
      end

      def parse(value)
        return nil if value.blank?
        if defined?(ActiveRecord) && value.is_a?(ActiveRecord::Base) &&
           value.respond_to?(:id) && value.id.is_a?(Integer)
          return value.id
        end
        return value if value.is_a?(Range)

        return nil if value.to_i.zero? && value.is_a?(String) && value !~ %r{\A\s*-?0}

        value.to_i
      end
    end
  end
end
