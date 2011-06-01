
module Datagrid
  module Filters
    require "datagrid/filters/base_filter"
    require "datagrid/filters/enum_filter"
    require "datagrid/filters/boolean_enum_filter"
    require "datagrid/filters/boolean_filter"
    require "datagrid/filters/date_filter"
    require "datagrid/filters/default_filter"
    require "datagrid/filters/filter_eval"
    require "datagrid/filters/integer_filter"


    require "datagrid/filters/composite_filters"

    def self.included(base)
      base.send(:include, Datagrid::Filters::CompositeFilters)
    end
  end
end
