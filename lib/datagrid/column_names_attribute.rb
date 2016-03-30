module Datagrid
  module ColumnNamesAttribute
    extend ActiveSupport::Concern

    included do
      datagrid_attribute :column_names do |names|
        names = Array(names).reject(&:blank?)
        if names.reject(&:blank?).blank?
          []
        else
          names
        end
      end
    end

    module ClassMethods
      # Adds a filter that acts like a column selection
      # All defined columns will be available to select/deselect
      # as a multi-select enum filter.
      # Columns with <tt>:mandatory => true</tt> option
      # will always present in the grid table and won't be listed
      # in column names selection
      # Accepts same options as <tt>:enum</tt> filter
      #
      # Examples:
      # 
      #   column_names_filter(:header => "Choose columns")
      #   
      def column_names_filter(options = {})
        filter(:column_names, :enum, {
          :select => :optional_columns_select,
          :multiple => true,
          :dummy => true
        }.merge(options || {}))
      end
    end

    def columns(*args) #:nodoc:
      options = args.extract_options!
      column_names = selected_column_names(*args)
      column_names << options
      super(*column_names)
    end

    # Returns a list of enabled columns with <tt>:mandatory => true</tt> option
    # If no mandatory columns specified than all of them considered mandatory
    def mandatory_columns
      available_columns.select {|c| c.mandatory? }
    end

    # Returns a list of enabled columns without <tt>:mandatory => true</tt> option
    def optional_columns
      available_columns - mandatory_columns
    end

    protected

    def optional_columns_select #:nodoc:
      optional_columns.map {|c| [c.header, c.name] }
    end

    def selected_column_names(*args)                  
      if args.any?
        args.compact!
        args.map!(&:to_sym)
        args
      else
        if column_names && column_names.any?
          column_names + mandatory_columns.map(&:name)
        else
          columns_enabled_by_default.map(&:name)
        end
      end
    end

    def columns_visibility_enabled?
      columns_array.any? do |column|
        column.options.key?(:mandatory)
      end
    end

    def columns_enabled_by_default
      columns_visibility_enabled? ? mandatory_columns : []
    end
  end
end

