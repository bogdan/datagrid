module Datagrid

  # Required to be ActiveModel compatible
  module Conversion
  
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        
      end
      base.send :include, InstanceMethods
    end # self.included
  
    module ClassMethods
  
      def param_name
        self.to_s.underscore.split('/').last
      end

      def model_name
        self.param_name
      end

    end # ClassMethods
  
    module InstanceMethods
  
      def param_name
        self.class.param_name
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

      def to_key
        nil
      end

      def to_param
        self.param_name
      end
    end # InstanceMethods
  
  end
    
  
end
