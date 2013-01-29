require "datagrid/utils"
require "active_support/core_ext/class/attribute"

module Datagrid

  module Columns
    require "datagrid/columns/column"

    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do

        include Datagrid::Core
        class_attribute :columns_array
        self.columns_array = []

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
          (!options[:data] || column.data?) && (args.empty? || args.include?(column.name))
        end
      end

      # Defines new datagrid column
      def column(name, options = {}, &block)
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.send(name)
        end
        columns_array << Datagrid::Columns::Column.new(self, name, options, &block)
      end

      def column_by_name(name)
        self.columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end

      def inherited(child_class)
        super(child_class)
        child_class.columns_array = self.columns_array.clone
      end

    end # ClassMethods

    module InstanceMethods

      # Returns <tt>Array</tt> of human readable column names. See also "Localization" section
      def header(*column_names)
        data_columns(*column_names).map(&:header)
      end

      # Returns <tt>Array</tt> column values for given asset
      def row_for(asset, *column_names)
        data_columns(*column_names).map do |column|
          column.value(asset, self)
        end
      end

      # Returns <tt>Hash</tt> where keys are column names and values are column values for the given asset
      def hash_for(asset)
        result = {}
        self.data_columns.each do |column|
          result[column.name] = column.value(asset, self)
        end
        result
      end

      # Returns Array of Arrays with data for each row in datagrid assets without header.
      def rows(*column_names)
        #TODO: find in batches
        self.assets.map do |asset|
          self.row_for(asset, *column_names)
        end
      end

      # Returns Array of Arrays with data for each row in datagrid assets with header.
      def data
        self.rows.unshift(self.header)
      end

      # Return Array of Hashes where keys are column names and values are column values 
      # for each row in datagrid <tt>#assets</tt>
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

      def columns(*args)
        self.class.columns(*args)
      end

      def data_columns(*names)
        names << {:data => true}
        self.columns(*names)
      end

      def column_by_name(name)
        self.class.column_by_name(name)
      end

    end # InstanceMethods

  end
end
