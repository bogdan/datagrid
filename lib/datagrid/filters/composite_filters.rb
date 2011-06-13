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


        def date_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
          filter(from_name, :date) do |date|
            self.from_date(date, field)
          end
          filter(to_name, :date) do |date|
            self.to_date(date, field)
          end
        end

        def integer_range_filters(field, from_name = :"from_#{field}", to_name = :"to_#{field}")
          filter(from_name, :integer) do |value|
            self.scoped(:conditions => "#{field} >= #{value}")
          end
          filter(to_name, :integer) do |value|
            self.scoped(:conditions => "#{field} <= #{value}")
          end
        end
      end # ClassMethods

      module InstanceMethods

      end # InstanceMethods

    end
  end
end
