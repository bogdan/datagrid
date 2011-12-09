module Datagrid
  module Columns
    module Html
    
      def self.included(base)
        base.extend         ClassMethods
        base.class_eval do
          
        end
        base.send :include, InstanceMethods
      end # self.included
    
      module ClassMethods
    
        def columns(options = {})
          super(options).reject do |column|
            options[:html] && column.html?
          end
        end

        def data_columns
          super(:html => false)
        end
      end # ClassMethods
    
      module InstanceMethods
    
      end # InstanceMethods
    
    end
  end
end



