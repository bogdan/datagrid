module Datagrid
  class Engine < Rails::Engine
    initializer "datagrid.helpers" do
      ActiveSupport.on_load :action_view do
        include Datagrid::Helper
      end 
    end 
  end
end
