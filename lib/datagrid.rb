require "action_view"
require "datagrid/configuration"

module Datagrid

  extend ActiveSupport::Autoload

  autoload :Core
  autoload :ActiveModel
  autoload :Filters
  autoload :Columns
  autoload :ColumnNamesAttribute
  autoload :Ordering
  autoload :Configuration

  autoload :Helper
  ActionView::Base.send(:include, Datagrid::Helper)
  
  autoload :FormBuilder
  ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)
  
  autoload :Renderer

  autoload :Engine

  def self.included(base)
    base.class_eval do

      include ::Datagrid::Core
      include ::Datagrid::ActiveModel
      include ::Datagrid::Filters
      include ::Datagrid::Columns
      include ::Datagrid::ColumnNamesAttribute
      include ::Datagrid::Ordering

    end
  end # self.included

  class ConfigurationError < StandardError; end
  class ArgumentError < ::ArgumentError; end
  class ColumnUnavailableError < StandardError; end

end

require "datagrid/scaffold"
I18n.load_path << File.expand_path('../datagrid/locale/en.yml', __FILE__)


