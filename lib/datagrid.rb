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
  ::ActiveSupport.on_load(:action_view) do
    ActionView::Base.send(:include, Datagrid::Helper)
  end

  autoload :FormBuilder
  ::ActiveSupport.on_load(:action_view) do
    ActionView::Helpers::FormBuilder.send(:include, Datagrid::FormBuilder)
  end

  autoload :Renderer

  autoload :Engine

  # @!visibility private
  def self.included(base)
    base.class_eval do

      include ::Datagrid::Core
      include ::Datagrid::ActiveModel
      include ::Datagrid::Filters
      include ::Datagrid::Columns
      include ::Datagrid::ColumnNamesAttribute
      include ::Datagrid::Ordering

    end
  end

  class ConfigurationError < StandardError; end
  class ArgumentError < ::ArgumentError; end
  class ColumnUnavailableError < StandardError; end

end

require "datagrid/scaffold"
I18n.load_path << File.expand_path('../datagrid/locale/en.yml', __FILE__)


