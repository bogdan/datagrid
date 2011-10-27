
module Datagrid
  module Drivers
    module Mongoid
    
      def self.included(base)
        base.extend         ClassMethods
        base.class_eval do
        end
        base.send :include, InstanceMethods
      end # self.included
    
      module ClassMethods

        def datagrid_scope
          scoped
        end

        def datagrid_where(condition)
          where(condition)
        end

        def datagrid_asc(order)
          asc(order)
        end

        def datagrid_desc(order)
          desc(order)
        end
    
      end # ClassMethods
    
      module InstanceMethods
    
      end # InstanceMethods
    
    end
  end
end
if defined?(::Mongoid)
  ::Mongoid::Document.included do
    include Datagrid::Drivers::Mongoid
  end
end
