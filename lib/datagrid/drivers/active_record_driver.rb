module Datagrid
  module Drivers
    module ActiveRecordDriver

      def self.included(base)
        base.extend         ClassMethods
        base.class_eval do
          base.send :include, InstanceMethods
        end # self.included
      end

      module ClassMethods
        def datagrid_scope
          scoped({})
        end

        def datagrid_where(condition)
          where(condition)
        end

        def datagrid_asc(order)
          reorder(order)
        end

        def datagrid_desc(order)
          # Rails 3.x.x don't able to override already applied order
          # Using #reorder instead
          reorder(order).reverse_order
        end

      end # ClassMethods

      module InstanceMethods

      end # InstanceMethods


    end

    ActiveRecord::Base.send(:include, ActiveRecordDriver) if defined?(ActiveRecord)

  end
end
