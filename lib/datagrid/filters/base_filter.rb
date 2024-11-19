# frozen_string_literal: true

# An error raise when datagrid filter is defined incorrectly and
# causes filtering chain to be broken
module Datagrid
  class FilteringError < StandardError
  end
end

module Datagrid
  module Filters
    class BaseFilter
      attr_accessor :grid_class, :options, :block, :name

      def initialize(grid_class, name, **options, &block)
        self.grid_class = grid_class
        self.name = name.to_sym
        self.options = options
        self.block = block
      end

      def parse(value)
        raise NotImplementedError, "#parse(value) suppose to be overwritten"
      end

      def default_input_options
        { type: "text" }
      end

      def unapplicable_value?(value)
        value.nil? ? !allow_nil? : value.blank? && !allow_blank?
      end

      def apply(grid_object, scope, value)
        return scope if unapplicable_value?(value)

        result = execute(value, scope, grid_object)

        return scope unless result

        result = default_filter(value, scope) if result == Datagrid::Filters::DEFAULT_FILTER_BLOCK
        unless grid_object.driver.match?(result)
          raise(
            Datagrid::FilteringError,
            "Filter #{name.inspect} unapplicable: result no longer match #{grid_object.driver.class}.",
          )
        end

        result
      end

      def parse_values(value)
        if multiple?
          return nil if value.nil?

          return normalize_multiple_value(value).map do |v|
            parse(v)
          end
        end

        case value
        when Array
          raise Datagrid::ArgumentError,
            "#{grid_class}##{name} filter can not accept Array argument. Use :multiple option."
        when Range
          raise Datagrid::ArgumentError,
            "#{grid_class}##{name} filter can not accept Range argument. Use :range option."
        else
          parse(value)
        end
      end

      def separator
        options[:multiple].is_a?(String) ? options[:multiple] : default_separator
      end

      def header
        if (header = options[:header])
          Datagrid::Utils.callable(header)
        else
          Datagrid::Utils.translate_from_namespace(:filters, grid_class, name)
        end
      end

      def default(object)
        default = options[:default]
        if default.is_a?(Symbol)
          object.send(default)
        elsif default.respond_to?(:call)
          Datagrid::Utils.apply_args(object, &default)
        else
          default
        end
      end

      def multiple?
        options[:multiple]
      end

      def range?
        false
      end

      def allow_nil?
        options.key?(:allow_nil) ? options[:allow_nil] : options[:allow_blank]
      end

      def allow_blank?
        options[:allow_blank]
      end

      def input_options
        options[:input_options] || {}
      end

      def label_options
        options[:label_options] || {}
      end

      def form_builder_helper_name
        self.class.form_builder_helper_name
      end

      def self.form_builder_helper_name
        :"datagrid_#{to_s.demodulize.underscore}"
      end

      def supports_range?
        self.class.ancestors.include?(::Datagrid::Filters::RangedFilter)
      end

      def format(value)
        value&.to_s
      end

      def dummy?
        options[:dummy]
      end

      def type
        Datagrid::Filters::FILTER_TYPES.each do |type, klass|
          return type if is_a?(klass)
        end
        raise "wtf is #{inspect}"
      end

      def enabled?(grid)
        ::Datagrid::Utils.process_availability(grid, options[:if], options[:unless])
      end

      def enum_checkboxes?
        false
      end

      def default_scope?
        !block
      end

      protected

      def default_filter_where(scope, value)
        driver.where(scope, name, value)
      end

      def execute(value, scope, grid_object)
        if block&.arity == 1
          scope.instance_exec(value, &block)
        elsif block
          Datagrid::Utils.apply_args(value, scope, grid_object, &block)
        else
          default_filter(value, scope)
        end
      end

      def normalize_multiple_value(value)
        case value
        when String
          value.split(separator)
        when Range
          [value.begin, value.end]
        when Array
          value
        else
          Array.wrap(value)
        end
      end

      def default_separator
        ","
      end

      def driver
        grid_class.driver
      end

      def default_filter(value, scope)
        return nil if dummy?

        if !driver.scope_has_column?(scope, name) && scope.respond_to?(name, true)
          scope.public_send(name, value)
        else
          default_filter_where(scope, value)
        end
      end
    end
  end
end
