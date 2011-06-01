module Datagrid
  module Columns
    require "datagrid/columns/column"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

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

      def columns
        self.class.columns
      end

      def data
        self.assets.scoped({}).map do |asset|
          self.row_for(asset)
        end
      end
    end # InstanceMethods

  end
end
