require "datagrid/columns"

module Datagrid
  class OrderUnsupported < StandardError
  end
  module Ordering

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        include Datagrid::Columns

        datagrid_attribute :order do |value|
          unless value.blank?
            value = value.to_sym
            column = column_by_name(value)
            unless column 
              order_unsupported(value, "no column #{value} in #{self.class}")
            end
            unless column.order
              order_unsupported(
                name, "#{self.class}##{name} don't support order" 
              ) 
            end
            value
          else
            nil
          end

        end

        datagrid_attribute :descending do |value|
          Datagrid::Utils.booleanize(value)
        end
        alias descending? descending

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def order_unsupported(name, reason)
        raise Datagrid::OrderUnsupported, "Can not sort #{self.inspect} by ##{name}: #{reason}"
      end

    end # ClassMethods

    module InstanceMethods

      def assets
        result = super
        if self.order
          column = column_by_name(self.order)
          result = apply_order(result, column)
        end
        result
      end

      private

      def apply_order(assets, column)

        # Rails 3.x.x don't able to override already applied order
        # Using #reorder instead

        order = column.order
        if self.descending?
          if column.order_desc
            assets.reorder(column.order_desc) 
          else
            assets.reorder(order).reverse_order
          end
        else
          assets.reorder(order)
        end
      end

    end # InstanceMethods

  end
end
