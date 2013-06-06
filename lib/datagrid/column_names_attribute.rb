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
      def column_names_filter
        filter(:column_names, :enum, :select => proc { UserReport.columns.map(&:name)}, :multiple => true ) do |value|
          scoped
        end
      end
    end

    def columns(*args)
      options = args.extract_options!
      column_names = selected_column_names(*args)
      column_names << options
      super(*column_names)
    end

    protected

    def selected_column_names(*args)
      if args.any?
        args.compact!
        args.map!(&:to_sym)
        args
      else
        column_names ? column_names.clone : []
      end
    end
  end
end

