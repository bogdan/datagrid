module Datagrid
  module Filters
    module CompositeFilters #:nodoc:

      def self.included(base)
        base.extend         ClassMethods
        base.class_eval do

        end
        base.send :include, InstanceMethods
      end # self.included

      module ClassMethods

        def date_range_filters(field, from_options = {}, to_options = {})
          range_filters(:date, field, from_options, to_options)
        end

        def time_range_filters(field, from_options = {}, to_options = {})
          range_filters(:datetime, field, from_options, to_options)
        end

        def integer_range_filters(field, from_options = {}, to_options = {})
          range_filters(:integer, field, from_options, to_options)
        end

        def normalize_composite_filter_options(options, field)
          if options.is_a?(String) || options.is_a?(Symbol)
            options = {:name => options}
          end
          options
        end

        private

        def range_filters(type, field, from_options = {}, to_options = {})
          from_options = normalize_composite_filter_options(from_options, field)
          to_options = normalize_composite_filter_options(to_options, field)

          filter(from_options[:name] || :"from_#{field.to_s.tr('.', '_')}", type, from_options) do |value, scope, grid|
            grid.driver.greater_equal(scope, field, value)
          end
          filter(to_options[:name] || :"to_#{field.to_s.tr('.', '_')}", type, to_options) do |value, scope, grid|
            grid.driver.less_equal(scope, field, value)
          end
        end
      end # ClassMethods

      module InstanceMethods


      end # InstanceMethods

    end
  end
end
