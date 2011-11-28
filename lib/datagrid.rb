require "datagrid/core"
require "datagrid/active_model"
require "datagrid/filters"
require "datagrid/columns"
require "datagrid/ordering"

require "datagrid/helper"
require "datagrid/form_builder"
require "datagrid/renderer"

require "datagrid/engine"

module Datagrid

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



