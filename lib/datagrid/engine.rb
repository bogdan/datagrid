require "rails/engine"
require 'datagrid/helper'
require 'datagrid/form_builder'

module Datagrid
  # @!private
  class Engine < ::Rails::Engine
    def self.extend_modules
      ActionView::Base.send(:include, Datagrid::Helper)
      ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)
    end

    initializer "datagrid.helpers" do
      ActiveSupport.on_load :action_view do
        Engine.extend_modules
      end
    end

  end
end
