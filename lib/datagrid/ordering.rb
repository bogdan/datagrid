# frozen_string_literal: true

require "datagrid/columns"

module Datagrid
  # Raised when grid order value is incorrect
  class OrderUnsupported < StandardError
  end

  # Module adds support for ordering by defined columns for Datagrid.
  module Ordering
    # @!visibility private
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        include Datagrid::Columns

        datagrid_attribute :order do |value|
          value.to_sym if value.present?
        end

        datagrid_attribute :descending do |value|
          Datagrid::Utils.booleanize(value)
        end
        alias_method :descending?, :descending
      end
    end

    # @!visibility private
    module ClassMethods
      def order_unsupported(name, reason)
        raise Datagrid::OrderUnsupported, "Can not sort #{inspect} by ##{name}: #{reason}"
      end
    end

    # @!method order=(value)
    #   Specify a column to be used to order the grid
    #   @param [Symbol, String] value column name
    #   @return [void]
    #   @example
    #     class MyGrid < ApplicationGrid
    #       scope { User }
    #       column(:name)
    #     end
    #
    #     grid = MyGrid.new
    #     grid.order = :name
    #     grid.descending = true
    #     grid.assets # => SELECT * FROM users ORDER BY users.name DESC

    # @!method order
    #   @return [Symbol, nil] specified order column name
    #   @see #order=

    # @!method descending=(value)
    #   Specify an order direction for an order column
    #   @param [Boolean] value specify `true` for descending order` or `false` for ascending
    #   @return [void]
    #   @see #order=

    # @!method descending?
    #   @return [Boolean] specified order direction
    #   @see #descending=

    # @!visibility private
    def assets
      check_order_valid!
      apply_order(super)
    end

    # @return [Datagrid::Columns::Column, nil] a column definition that is currently used to order assets
    # @example
    #   class MyGrid
    #     scope { Model }
    #     column(:id)
    #     column(:name)
    #   end
    #   MyGrid.new(order: "name").order_column # => #<Column name: "name", ...>
    def order_column
      order ? column_by_name(order) : nil
    end

    # @param column [String, Datagrid::Columns::Column]
    # @param desc [nil, Boolean] confirm order direction as well if specified
    # @return [Boolean] true if given grid is ordered by given column.
    def ordered_by?(column, desc = nil)
      order_column == column_by_name(column) &&
        (desc.nil? || (desc ? descending? : !descending?))
    end

    private

    def apply_order(assets)
      return assets unless order

      if order_column.order_by_value?
        assets = assets.sort_by do |asset|
          order_column.order_by_value(asset, self)
        end
        descending? ? assets.reverse : assets
      elsif descending?
        if order_column.order_desc
          apply_asc_order(assets, order_column.order_desc)
        else
          apply_desc_order(assets, order_column.order)
        end
      else
        apply_asc_order(assets, order_column.order)
      end
    end

    def check_order_valid!
      return unless order

      column = column_by_name(order)
      self.class.order_unsupported(order, "no column #{order} in #{self.class}") unless column
      return if column.supports_order?

      self.class.order_unsupported(column.name, "column don't support order")
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
      self.class.order_unsupported(order_column.name,
        "Your ORM do not support reverse order: please specify :order_desc option manually",)
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
  end
end
