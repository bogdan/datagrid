require "datagrid/form_builder"
require "datagrid/filters"
require "datagrid/columns"
require "datagrid/core"

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


  def to_param
    :report
  end


end



