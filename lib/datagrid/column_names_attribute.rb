module Datagrid
  module ColumnNamesAttribute
    extend ActiveSupport::Concern

    included do
      class_attribute :columns_array
      self.columns_array = []

      datagrid_attribute :column_names do |names|
        names = Array(names).reject(&:blank?)
        if names.reject(&:blank?).blank?
          columns.map(&:name)
        else
          names
        end
      end
    end

    module ClassMethods
      # Adds a filter that acts like a column selection
      def column_names_filter
        filter(
          :column_names, :enum, 
          :select => :optional_columns_select,
          :multiple => true,
          :dummy => true
        )
      end
    end

    def columns(*args) #:nodoc:
      options = args.extract_options!
      column_names = selected_column_names(*args)
      column_names << options
      super(*column_names)
    end

    # Returns a list of columns with <tt>:mandatory => true</tt> option
    def mandatory_columns
      self.class.columns.select(&:mandatory?)
    end

    # Returns a list of columns without <tt>:mandatory => true</tt> option
    def optional_columns
      self.class.columns.reject(&:mandatory?)
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
        column_names ? column_names + mandatory_columns.map(&:name) : []
      end
    end

  end
end

