# frozen_string_literal: true

require "action_view"
require "datagrid/configuration"
require "datagrid/engine"

# @main README.md
module Datagrid
  # @!visibility private
  def self.included(base)
    Utils.warn_once("Including Datagrid is deprecated. Inherit Datagrid::Base instead.")
    base.class_eval do
      include ::Datagrid::Core
      include ::Datagrid::ActiveModel
      include ::Datagrid::Filters
      include ::Datagrid::Columns
      include ::Datagrid::ColumnNamesAttribute
      include ::Datagrid::Ordering
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Configure
  def self.configure(&block)
    block.call(configuration)
  end

  class ConfigurationError < StandardError; end
  class ArgumentError < ::ArgumentError; end
  class ColumnUnavailableError < StandardError; end
end

require "datagrid/base"
require "datagrid/generators/scaffold"
require "datagrid/generators/views"
I18n.load_path << File.expand_path("datagrid/locale/en.yml", __dir__)
