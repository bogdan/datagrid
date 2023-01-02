module Datagrid
  # Required to be ActiveModel compatible
  module ActiveModel
    # @!visibility private
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        begin
          require 'active_model/naming'
          extend ::ActiveModel::Naming
        rescue LoadError
        end
        begin
          require 'active_model/attributes_assignment'
          extend ::ActiveModel::AttributesAssignment
        rescue LoadError
        end
      end
    end

    module ClassMethods
      # @return [String] URL query parameter name of the grid class
      def param_name
        self.to_s.underscore.tr('/', '_')
      end
    end

    # @return [String] URL query parameter name of the grid class
    def param_name
      self.class.param_name
    end

    # @return [String] URL query parameter name of the grid class
    def param_key
      param_name
    end

    def to_key
      [self.class.param_name]
    end

    def persisted?
      false
    end

    def to_model
      self
    end

    def to_param
      self.param_name
    end
  end
end
