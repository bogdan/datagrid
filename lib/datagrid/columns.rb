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

      # Defines column that will be used to display data.
      # 
      # Example:
      #     
      #   class UserGrid 
      #     include Datagrid
      #
      #     scope do
      #       User.order("users.created_at desc").includes(:group)
      #     end
      #
      #     column(:name)
      #     column(:group, :order => "groups.name")
      #       self.group.name
      #     end
      #     column(:active, :header => "Activated") do |user|
      #       !user.disabled
      #     end
      #
      #   end
      #
      # Each column will be used to generate data.
      # In order to create grid that display all users:
      #
      #   grid = UserGrid.new
      #   grid.rows 
      #   grid.header # => ["Group", "Name", "Disabled"]
      #   grid.rows   # => [
      #               #      ["Steve", "Spammers", true],
      #               #      [ "John", "Spoilers", true],
      #               #      ["Berry", "Good people", false]
      #               #    ]
      #   grid.data   # => Header & Rows
      #
      # = Column value
      #
      # Column value can be defined by passing a block to <tt>#column</tt> method.
      # If no block given column is generated automatically by sending column name method to model.
      # The block could have zero arguments(<tt>instance_eval</tt>) or one argument that is model object.
      #
      # = Columns order
      #
      # Each column supports <tt>:order</tt> option that is used to specify SQL to sort data by the given column.
      # In order to specify order for the given grid the following attributes are used:
      #
      # * <tt>:order</tt> - column name to use order. Default: nil.
      # * <tt>:reverse</tt> - if true descending suffix is added to specified order. Default: false.
      #
      # 
      # Example:
      #
      # grid = UserGrid.new(:order => :group, :reverse => true)
      # grid.assets # => Return assets ordered by :group column descending
      #
      # = Options
      #
      # TODO
      def column(name, options = {}, &block)
        block ||= lambda do |model|
          model.send(name)
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

      def rows
        self.assets.map do |asset|
          self.row_for(asset)
        end
      end

      def data
        self.rows.unshift(self.header)
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
          result = result.order(self.reverse ? column.desc_order : column.order)
        end
        result
      end

      def to_csv(options = {})
        require "fastercsv"
        FasterCSV.generate(
          {:headers => self.header, :write_headers => true}.merge(options)
        ) do |csv|
          self.rows.each do |row|
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
