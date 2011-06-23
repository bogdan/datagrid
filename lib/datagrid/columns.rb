require "datagrid/utils"

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
        datagrid_attribute :descending do |value|
          Datagrid::Utils.booleanize(value)
        end


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
      # Column value can be defined by passing a block to <tt>Datagrid.column</tt> method.
      # If no block given column it is generated automatically by sending column name method to model.
      # 
      #   column(:name) # => asset.name
      #
      # The block could have no arguments(<tt>instance_eval</tt> for each asset will be used). 
      #
      #   column(:completed) { self.completed? }
      #
      # If you don't like <tt>instance_eval</tt> you can use asset as first argument:
      #
      #   column(:completed { |asset| asset.completed? }
      #
      # For the most complicated columns you can also pass datagrid object itself:
      #
      #   filter(:category) do |value|
      #     where("category LIKE '%#{value}%'")
      #   end
      #
      #   column(:exact_category) do |asset, grid|
      #     asset.category == grid.category
      #   end
      #
      # = Ordering
      #
      # Each column supports the following options that is used to specify SQL to sort data by the given column:
      #
      # * <tt>:order</tt> - an order SQL that should be used to sort by this column. 
      # Default: report column name if there is database column with this name.
      # * <tt>:order_desc</tt> - descending order expression from this column. Default: "#{order} desc".
      #
      #   column(:group_name, :order => "groups.name)
      #
      #   # Suppose that assets with null priority should be always on bottom.
      #   column(:priority, :order => "priority is not null desc, priority", :order_desc => "prioritty is not null desc, priority desc")
      #
      # In order to specify order the following attributes are used for <tt>Datagrid</tt> instance:
      #
      # * <tt>:order</tt> - column name to sort with as <tt>Symbol</tt>. Default: nil.
      # * <tt>:descending</tt> - if true descending suffix is added to specified order. Default: false.
      #
      #   UserGrid.new(:order => :group, :descending => true).assets # => assets ordered by :group column descending
      #
      # = Localization
      #
      # Column header can be specified with <tt>:header</tt> option.
      # By default it is generated from column name.
      # Also you can use localization file if you have multilanguage application.
      #
      # Example: In order to localize column <tt>:name</tt> in <tt>SimpleReport</tt> 
      # use the key <tt>datagrid.simple_report.columns.name</tt>
      # 
      #
      def column(name, options = {}, &block)
        check_scope_defined!("Scope should be defined before columns")
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
          column.value(asset, self)
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
          result = result.order(self.descending ? column.desc_order : column.order)
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
