module Datagrid
  module Filters
    module CompositeFilters

      def self.included(base)
        base.extend         ClassMethods
        base.class_eval do

        end
        base.send :include, InstanceMethods
      end # self.included

      module ClassMethods

        def date_range_filters(field, from_options = {}, to_options = {})
          from_options = normalize_composite_filter_options(from_options, field)
          to_options = normalize_composite_filter_options(to_options, field)

          filter(from_options[:name] || :"from_#{field}", :date) do |date|
            driver.greater_equal(self, field, date)
          end
          filter(to_options[:name] || :"to_#{field}", :date) do |date|
            driver.less_equal(self, field, date)
          end
        end

        def integer_range_filters(field, from_options = {}, to_options = {})
          from_options = normalize_composite_filter_options(from_options, field)
          to_options = normalize_composite_filter_options(to_options, field)
          filter(from_options[:name] || :"from_#{field}", :integer) do |value|
            driver.greater_equal(self, field, value)
          end
          filter(to_options[:name] || :"to_#{field}", :integer) do |value|
            driver.less_equal(self, field, value)
          end
        end

        def normalize_composite_filter_options(options, field)
          if options.is_a?(String) || options.is_a?(Symbol)
            options = {:name => options}
          end
          options
        end
      end # ClassMethods

      module InstanceMethods


      end # InstanceMethods

    end
  end
end
