module Datagrid
  
  class OrderUnsupported < StandardError
  end
  
  module Columns
    require "datagrid/columns/column"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core

        datagrid_attribute :order
        datagrid_attribute :reverse

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      def columns
        @columns ||= []
      end

      def column(name, options = {}, &block)
        block ||= lambda do
          self.send(name)
        end
        self.columns << Datagrid::Columns::Column.new(self, name, options, &block)
      end


    end # ClassMethods

    module InstanceMethods

      def header
        self.class.columns.map(&:header)
      end

      def row_for(asset)
        self.class.columns.map do |column|
          column.value(asset)
        end
      end

      def hash_for(asset)
        result = {}
        self.class.columns.each do |column|
          result[column.name] = column.value(asset)
        end
        result
      end

      def data
        self.assets.map do |asset|
          self.row_for(asset)
        end
      end

      def data_hash
        self.assets.map do |asset|
          hash_for(asset)
        end
      end

      def assets
        result = super
        if self.order
          column = column_by_name(self.order)
          raise Datagrid::OrderUnsupported, "Can not sort #{self.inspect} by #{name.inspect}" unless column
          result = result.order(self.reverse ? column.order : column.desc_order)
        end
        result
      end

      def to_csv(options = {})
        require "fastercsv"
        FasterCSV.generate(
          {:headers => self.header, :write_headers => true}.merge(options)
        ) do |csv|
          self.data.each do |row|
            csv << row
          end
        end
      end

      def columns
        self.class.columns
      end

      def column_by_name(name)
        self.columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end

    end # InstanceMethods

  end
end
