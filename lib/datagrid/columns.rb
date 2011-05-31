module Datagrid
  module Columns
    require "datagrid/columns/column"
  
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval do
        
      end
      base.send :include, InstanceMethods
    end # self.included
  
    module ClassMethods
  
    end # ClassMethods
  
    module InstanceMethods
  
    end # InstanceMethods
  
  end
end
