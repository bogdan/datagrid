require "datagrid/engine"
require "action_view"

module Datagrid
  module Helper

    def datagrid_format_value(report, column, asset)
      Renderer.for(self).format_value(report, column, asset)
    end

    def datagrid_table(report, *args)
      Renderer.for(self).table(report, *args)
    end

    def datagrid_header(grid, options = {})
      Renderer.for(self).header(grid, options)
    end

    def datagrid_rows(report, assets, options = {})
      Renderer.for(self).rows(report, assets, options)
    end

    def datagrid_order_for(grid, column)
      Renderer.for(self).order_for(grid, column)
    end

    protected
    def empty_string
      _safe("")
    end

    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end

    def datagrid_render_column(column, asset)
      instance_exec(asset, &column.block)
    end

    def datagrid_column_classes(grid, column)
        order_class = grid.order == column.name ? ["ordered", grid.descending ? "desc" : "asc"] : nil
      [column.name, order_class].compact.join(" ")
    end
  end
end
ActionView::Base.send(:include, Datagrid::Helper)
