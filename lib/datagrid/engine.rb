require "rails/engine"
require 'datagrid/helper'
require 'datagrid/form_builder'

module Datagrid
  # @!private
  class Engine < ::Rails::Engine
    initializer "datagrid.helpers" do
      ActiveSupport.on_load :action_view do
        ActionView::Base.send(:include, Datagrid::Helper)
        ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)
      end
    end
  end
end
