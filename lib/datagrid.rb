module Datagrid

  extend ActiveSupport::Autoload

  autoload :Core
  autoload :ActiveModel
  autoload :Filters
  autoload :Columns
  autoload :Ordering

  autoload :Helper
  ActionView::Base.send(:include, Datagrid::Helper)
  
  autoload :FormBuilder
  ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)
  
  autoload :Renderer

  autoload :Engine

  def self.included(base)
    base.extend         ClassMethods
    base.class_eval do

      include ::Datagrid::Core
      include ::Datagrid::ActiveModel
      include ::Datagrid::Filters
      include ::Datagrid::Columns
      include ::Datagrid::Ordering

    end
    base.send :include, InstanceMethods
  end # self.included

  module ClassMethods


  end # ClassMethods

  module InstanceMethods

  end # InstanceMethods

  class ConfigurationError < StandardError; end
  class ArgumentError < StandardError; end


end



