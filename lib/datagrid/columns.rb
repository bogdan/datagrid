require "datagrid/utils"
require "active_support/core_ext/class/attribute"

module Datagrid

  module Columns
    require "datagrid/columns/column"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core

      end
      base.send :include, InstanceMethods
    end # self.included

    module ClassMethods

      # Returns a list of columns defined.
      # All column definistion are returned by default
      # You can limit the output with only columns you need like:
      #
      #   grid.columns(:id, :name)
      #
      # Supported options:
      #
      # * :data - if true returns only non-html columns. Default: false.
      def columns(*args)
        options = args.extract_options!
        args.compact!
        args.map!(&:to_sym)
        columns_array.select do |column|
          (!options[:data] || column.data?) && (!options[:html] || column.html?)&& (args.empty? || args.include?(column.name))
        end
      end

      # Defines new datagrid column
      # 
      # Arguments:
      #
      #   * <tt>name</tt> - column name
      #   * <tt>options</tt> - hash of options
      #   * <tt>block</tt> - proc to calculate a column value
      #
      # Available options:
      #   
      #   * <tt>:html</tt> - determines if current column should be present in html table and how is it formatted
      #   * <tt>:order</tt> - determines if this column could be sortable and how
      #   * <tt>:order_desc</tt> - determines a descending order for given column (only in case when <tt>:order</tt> can not be easily inverted
      #   * <tt>:url</tt> - a proc with one argument, pass this option to easily convert the value into an URL
      #
      # See: https://github.com/bogdan/datagrid/wiki/Columns for examples
      def column(name, options = {}, &block)
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.send(name)
        end
        columns_array << Datagrid::Columns::Column.new(self, name, options, &block)
      end

      # Returns column definition with given name
      def column_by_name(name)
        self.columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end

      # Returns an array of all defined column names
      def column_names
        columns.map(&:name)
      end

      def respond_to(&block) #:nodoc:
        Datagrid::Columns::Column::ResponseFormat.new(&block)
      end

      def format(value, &block)
        if block_given?
          respond_to do |f|
            f.data { value }
            f.html do
              instance_exec(value, &block)
            end
          end
        else
          # Ruby Object#format exists. 
          # We don't want to change the behaviour and overwrite it.
          super
        end
      end

      def inherited(child_class) #:nodoc:
        super(child_class)
        child_class.columns_array = self.columns_array.clone
      end

    end # ClassMethods

    module InstanceMethods

      # Returns <tt>Array</tt> of human readable column names. See also "Localization" section
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def header(*column_names)
        data_columns(*column_names).map(&:header)
      end

      # Returns <tt>Array</tt> column values for given asset
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def row_for(asset, *column_names)
        data_columns(*column_names).map do |column|
          column.data_value(asset, self)
        end
      end

      # Returns <tt>Hash</tt> where keys are column names and values are column values for the given asset
      def hash_for(asset)
        result = {}
        self.data_columns.each do |column|
          result[column.name] = column.data_value(asset, self)
        end
        result
      end

      # Returns Array of Arrays with data for each row in datagrid assets without header.
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def rows(*column_names)
        #TODO: find in batches
        self.assets.map do |asset|
          self.row_for(asset, *column_names)
        end
      end

      # Returns Array of Arrays with data for each row in datagrid assets with header.
      #
      # Arguments:
      #
      #   * <tt>column_names</tt> - list of column names if you want to limit data only to specified columns
      def data(*column_names)
        self.rows(*column_names).unshift(self.header(*column_names))
      end

      # Return Array of Hashes where keys are column names and values are column values 
      # for each row in datagrid <tt>#assets</tt>
      #
      # Example:
      #
      #     class MyGrid
      #       scope { Model }
      #       column(:id)
      #       column(:name)
      #     end
      #
      #     Model.create!(:name => "One")
      #     Model.create!(:name => "Two")
      #
      #     MyGrid.new.data_hash # => [{:name => "One"}, {:name => "Two"}]
      #
      def data_hash
        self.assets.map do |asset|
          hash_for(asset)
        end
      end

      # Returns a CSV representation of the data in the table
      # You are able to specify which columns you want to see in CSV.
      # All data columns are included by default
      # Also you can specify options hash as last argument that is proxied to
      # Ruby CSV library.
      #
      # Example:
      #
      #   grid.to_csv
      #   grid.to_csv(:id, :name)
      #   grid.to_csv(:col_sep => ';')
      def to_csv(*column_names)
        options = column_names.extract_options!
        klass = if RUBY_VERSION >= "1.9"
                  require 'csv'
                  CSV
                else
                  require "fastercsv"
                  FasterCSV
                end
        klass.generate(
          {:headers => self.header(*column_names), :write_headers => true}.merge(options)
        ) do |csv|
          self.rows(*column_names).each do |row|
            csv << row
          end
        end
      end


      # Returns all columns selected in grid instance
      #
      # Examples:
      # 
      #   MyGrid.new.columns # => all defined columns
      #   grid = MyGrid.new(:column_names => [:id, :name])
      #   grid.columns # => id and name columns
      #   grid.columns(:id, :category) # => id and category column
      def columns(*args)
        self.class.columns(*args)
      end

      # Returns all columns that can be represented in plain data(non-html) way
      def data_columns(*names)
        options = names.extract_options!
        options[:data] = true
        names << options
        self.columns(*names)
      end

      # Returns all columns that can be represented in HTML table
      def html_columns(*names)
        options = names.extract_options!
        options[:html] = true
        names << options
        self.columns(*names)
      end

      # Finds a column by name
      def column_by_name(name)
        self.class.column_by_name(name)
      end


      def format(value, &block)
        if block_given?
          self.class.format(value, &block)
        else
          super
        end
      end

    end # InstanceMethods

  end
end
