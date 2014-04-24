
module Datagrid

  # Required to be ActiveModel compatible
  # @private
  module ActiveModel #:nodoc:
  
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        begin
          require 'active_model/naming'
          extend ::ActiveModel::Naming
        rescue LoadError
        end
      end
      base.send :include, InstanceMethods
    end # self.included
  
    module ClassMethods
  
      def param_name
        self.to_s.underscore.tr('/', '_')
      end


    end # ClassMethods
  
    module InstanceMethods
  
      def param_name
        self.class.param_name
      end

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
    end # InstanceMethods
  
  end
    
  
end
