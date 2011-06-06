require "datagrid/filters"
require "datagrid/columns"
require "datagrid/core"

require "datagrid/helper"
require "datagrid/form_builder"

module Datagrid

  def self.included(base)
    base.extend         ClassMethods
    base.class_eval do

      include ::Datagrid::Core
      include ::Datagrid::Filters
      include ::Datagrid::Columns

    end
    base.send :include, InstanceMethods
  end # self.included

  module ClassMethods


  end # ClassMethods

  module InstanceMethods

  end # InstanceMethods

  class ConfigurationError < StandardError; end


end



