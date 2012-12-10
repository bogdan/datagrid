require "datagrid/engine"
require "action_view"

module Datagrid
  module Helper

    def datagrid_format_value(report, column, asset)
      datagrid_renderer.format_value(report, column, asset)
    end

    def datagrid_table(report, *args)
      datagrid_renderer.table(report, *args)
    end

    def datagrid_header(grid, options = {})
      datagrid_renderer.header(grid, options)
    end

    def datagrid_rows(report, assets, options = {})
      datagrid_renderer.rows(report, assets, options)
    end

    def datagrid_order_for(grid, column)
      datagrid_renderer.order_for(grid, column)
    end

    protected

    def datagrid_renderer
      Renderer.for(self)
    end

    def datagrid_column_classes(grid, column)
      order_class = grid.order == column.name ? ["ordered", grid.descending ? "desc" : "asc"] : nil
      [column.name, order_class, column.options[:class]].compact.join(" ")
    end
  end
end

