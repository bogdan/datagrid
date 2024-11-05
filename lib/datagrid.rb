# frozen_string_literal: true

require "action_view"
require "datagrid/configuration"
require "datagrid/engine"

# Main datagrid module that needs to be included in grid class
#
# @example
#   class UsersGrid
#     include Datagrid
#     scope { User }
#     column(:id)
#     column(:name)
#   end
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
  autoload :FormBuilder

  autoload :Renderer

  autoload :Engine

  # extend ActiveSupport::Concern

  # included do
    # include ::Datagrid::Core
    # include ::Datagrid::ActiveModel
    # include ::Datagrid::Filters
    # include ::Datagrid::Columns
    # include ::Datagrid::ColumnNamesAttribute
    # include ::Datagrid::Ordering
  # end
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
I18n.load_path << File.expand_path("datagrid/locale/en.yml", __dir__)
