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
        #TODO: decide what to do with cross-orm

        def date_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
          filter(from_name, :date) do |date|
            driver.greater_equal(self, field, date)
          end
          filter(to_name, :date) do |date|
            driver.less_equal(self, field, date)
          end
        end

        def integer_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
          filter(from_name, :integer) do |value|
            driver.greater_equal(self, field, value)
          end
          filter(to_name, :integer) do |value|
            driver.less_equal(self, field, value)
          end
        end
      end # ClassMethods

      module InstanceMethods

      end # InstanceMethods

    end
  end
end
