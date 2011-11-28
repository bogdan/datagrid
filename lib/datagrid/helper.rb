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

    def datagrid_rows(report, assets, options)
      Renderer.for(self).rows(report, assets, options)
    end

    def datagrid_order_for(grid, column)
      Renderer.for(self).order_for(grid, column)
    end

  end
end
