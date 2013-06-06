require "datagrid/engine"
require "action_view"

module Datagrid
  module Helper

    # Format an value from datagrid column with given name and for given model
    def datagrid_format_value(report, column_name, model)
      datagrid_renderer.format_value(report, column_name, model)
    end

    # Renders html table with columns defined in grid class.
    # In the most common used you need to pass paginated collection 
    # to datagrid table because datagrid do not have pagination compatibilities:
    #     
    #   assets = grid.assets.page(params[:page])
    #   datagrid_table(grid, assets, options)
    #
    # Supported options:
    #
    # * <tt>:html</tt> - hash of attributes for <table> tag
    # * <tt>:order</tt> - If false do not generate ordering controlls. 
    #   Default: true.
    # * <tt>:cycle</tt> - Used as arguments for cycle for each row. 
    #   Default: false. Example: <tt>["odd", "even"]</tt>.
    # * <tt>:columns</tt> - Array of column names to display. 
    #   Used in case when same grid class is used in different places 
    #   and needs different columns. Default: all defined columns.
    def datagrid_table(report, *args)
      datagrid_renderer.table(report, *args)
    end

    # Renders HTML table header for given grid instance using columns defined in it
    #
    # Supported options:
    #
    # * <tt>:order</tt> - display ordering controls built-in into header
    #   Default: true
    #     
    def datagrid_header(grid, options = {})
      datagrid_renderer.header(grid, options)
    end


    # Renders HTML table rows using given grid definition using columns defined in it
    def datagrid_rows(report, assets, options = {})
      datagrid_renderer.rows(report, assets, options)
    end

    # Renders ordering controls for the given column name
    def datagrid_order_for(grid, column)
      datagrid_renderer.order_for(grid, column)
    end

    # Renders HTML for for grid with all filters inputs and lables defined in it
    def datagrid_form_for(grid, options = {})
      datagrid_renderer.form_for(grid, options)
    end

    # Provides access to datagrid column data.
    #
    #   <%= datagrid_row(grid, user) do |row| %>
    #     <tr>
    #       <td><%= row.first_name %></td>
    #       <td><%= row.last_name %></td>
    #     </tr>
    #   <% end %>
    #
    # Used in case you want to build datagrid table completelly manually
    def datagrid_row(grid, asset, &block)
      HtmlRow.new(self, grid, asset).tap do |row|
        if block_given?
          return capture(row, &block)
        end
      end
    end

    class HtmlRow
      def initialize(context, grid, asset)
        @context = context
        @grid = grid
        @asset = asset
      end 

      def method_missing(method, *args, &blk)
        if column = @grid.column_by_name(method)
          @context.datagrid_format_value(@grid, column, @asset)
        else
          super
        end
      end
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

