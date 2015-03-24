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
          if value.present?
            value.to_sym
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

      def assets # :nodoc:
        check_order_valid!
        apply_order(super)
      end

      # Returns a column definition that is currently used to order assets
      # 
      #   class MyGrid
      #     scope { Model }
      #     column(:id)
      #     column(:name)
      #   end
      #   MyGrid.new(:order => "name").order_column # => #<Column name: "name", ...>
      #
      def order_column
        order && column_by_name(order)
      end

      # Returns true if given grid is ordered by given column.
      # <tt>column</tt> can be given as name or as column object
      def ordered_by?(column)
        order_column == column_by_name(column)
      end

      private

      def apply_order(assets)
        return assets unless order
        if order_column.order_by_value?
          assets = assets.sort_by do |asset|
            order_column.order_by_value(asset, self)
          end
          descending? ? assets.reverse : assets
        else
          if descending?
            if order_column.order_desc
              apply_asc_order(assets, order_column.order_desc)
            else
              apply_desc_order(assets, order_column.order)
            end
          else
            apply_asc_order(assets, order_column.order)
          end
        end
      end

      def check_order_valid!
        return unless order
        column = column_by_name(order)
        unless column 
          self.class.order_unsupported(order, "no column #{order} in #{self.class}")
        end
        unless column.supports_order?
          self.class.order_unsupported(column.name, "column don't support order" ) 
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
        self.class.order_unsupported(order_column.name, "Your ORM do not support reverse order: please specify :order_desc option manually")
      end

      def apply_block_order(assets, order)
        case order.arity 
        when -1, 0
          assets.instance_eval(&order)
        when 1
          order.call(assets)
        else
          self.class.order_unsupported(order_column.name, "Order option proc can not handle more than one argument")
        end
      end
    end # InstanceMethods

  end
end
