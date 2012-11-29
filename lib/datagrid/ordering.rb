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
        if order
          column = column_by_name(order)
          result = apply_order(result, column)
        end
        result
      end

      private

      def apply_order(assets, column)
        if descending?
          if column.order_desc
            apply_asc_order(assets, column.order_desc)
          else
            apply_desc_order(assets, column.order)
          end
        else
          apply_asc_order(assets, column.order)
        end
      end

      def apply_asc_order(assets, order)
        if order.respond_to?(:call)
          apply_block_order(assets, order)
        else
          driver.asc(assets, order) 
        end
      end

      def apply_desc_order(assets, order)
        if order.respond_to?(:call)
          reverse_order(apply_asc_order(assets, order))
        else
          driver.desc(assets, order)
        end
      end

      def reverse_order(assets)
        driver.reverse_order(assets)
      rescue NotImplementedError
        self.class.order_unsupported("Your ORM do not support reverse order: please specify :order_desc option manually")
      end

      def apply_block_order(assets, order)
        case order.arity 
        when -1, 0
          assets.instance_eval(&order)
        when 1
          order.call(assets)
        else
          self.class.order_unsupported("Order option proc can not handle more than one argument")
        end
      end
    end # InstanceMethods

  end
end
