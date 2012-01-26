require "datagrid/utils"

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

      def columns(options = {})
        (@columns ||= []).reject do |column|
          options[:data] && column.html?
        end
      end

      def column(name, options = {}, &block)
        check_scope_defined!("Scope should be defined before columns")
        block ||= lambda do |model|
          model.send(name)
        end
        @columns ||= []
        @columns << Datagrid::Columns::Column.new(self, name, options, &block)
      end

      def column_by_name(name)
        self.columns.find do |col|
          col.name.to_sym == name.to_sym
        end
      end
    end # ClassMethods

    module InstanceMethods

      # Returns <tt>Array</tt> of human readable column names. See also "Localization" section
      def header
        self.data_columns.map(&:header)
      end

      # Returns <tt>Array</tt> column values for given asset
      def row_for(asset)
        self.data_columns.map do |column|
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

      def to_csv(options = {})
        klass = if RUBY_VERSION >= "1.9"
                  require 'csv'
                  CSV
                else
                  require "fastercsv"
                  FasterCSV
                end
        klass.generate(
          {:headers => self.header, :write_headers => true}.merge(options)
        ) do |csv|
          self.rows.each do |row|
            csv << row
          end
        end
      end

      def columns(options ={})
        self.class.columns(options)
      end

      def data_columns
        self.columns(:data => true)
      end

      def column_by_name(name)
        self.class.column_by_name(name)
      end

    end # InstanceMethods

  end
end
