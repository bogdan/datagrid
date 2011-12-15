require "rails/engine"

module Datagrid
  class Engine < ::Rails::Engine
    initializer "datagrid.helpers" do
      #TODO: check why it doesn't work
      ActiveSupport.on_load :action_view do
        include Datagrid::Helper
      end 
    end 
  end
end
