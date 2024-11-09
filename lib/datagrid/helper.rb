# frozen_string_literal: true

require "action_view"

module Datagrid
  # Datagrid methods available as helpers in Rails views
  module Helper
    # @param grid [Datagrid] grid object
    # @param column [Datagrid::Columns::Column, String, Symbol] column name
    # @param model [Object] an object from grid scope
    # @return [Object] individual cell value from the given grid, column name and model
    # @example
    #   <ul>
    #     <% @grid.columns.each do |column|
    #       <li><%= column.header %>: <%= datagrid_value(@grid, column.name, @resource %></li>
    #     <% end %>
    #   </ul>
    def datagrid_value(grid, column, model)
      datagrid_renderer.format_value(grid, column, model)
    end

    # @!visibility private
    def datagrid_format_value(grid, column, model)
      datagrid_value(grid, column, model)
    end

    # Renders html table with columns defined in grid class.
    # In the most common used you need to pass paginated collection
    # to datagrid table because datagrid do not have pagination compatibilities:
    # Supported options:
    #
    # * <tt>:html</tt> - hash of attributes for <table> tag
    # * <tt>:order</tt> - If false do not generate ordering controlls.
    #   Default: true.
    # * <tt>:columns</tt> - Array of column names to display.
    #   Used in case when same grid class is used in different places
    #   and needs different columns. Default: all defined columns.
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    # @param grid [Datagrid] grid object
    # @param assets [Array] objects from grid scope
    # @return [String] table tag HTML markup
    # @example
    #   assets = grid.assets.page(params[:page])
    #   datagrid_table(grid, assets, options)
    def datagrid_table(grid, assets = grid.assets, **options)
      datagrid_renderer.table(grid, assets, **options)
    end

    # Renders HTML table header for given grid instance using columns defined in it
    #
    # Supported options:
    #
    # * <tt>:order</tt> - display ordering controls built-in into header
    #   Default: true
    # * <tt>:columns</tt> - Array of column names to display.
    #   Used in case when same grid class is used in different places
    #   and needs different columns. Default: all defined columns.
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    # @param grid [Datagrid] grid object
    # @return [String] HTML table header tag markup
    def datagrid_header(grid, options = {})
      datagrid_renderer.header(grid, options)
    end

    # Renders HTML table rows using given grid definition using columns defined in it.
    # Allows to provide a custom layout for each for in place with a block
    #
    # Supported options:
    #
    # * <tt>:columns</tt> - Array of column names to display.
    #   Used in case when same grid class is used in different places
    #   and needs different columns. Default: all defined columns.
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    #
    # @return [String]
    # @example
    #   = datagrid_rows(grid) # Generic table rows Layout
    #
    #   = datagrid_rows(grid) do |row| # Custom Layout
    #     %tr
    #       %td= row.project_name
    #       %td.project-status{class: row.status}= row.status
    def datagrid_rows(grid, assets = grid.assets, **options, &block)
      datagrid_renderer.rows(grid, assets, **options, &block)
    end

    # @return [String] renders ordering controls for the given column name
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_order_for(grid, column, options = {})
      datagrid_renderer.order_for(grid, column, options)
    end

    # Renders HTML for grid with all filters inputs and labels defined in it
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for form partial lookup.
    #   Default: 'datagrid' results in using `app/views/datagrid/` partials.
    #   Example: 'datagrid_admin' results in using `app/views/datagrid_admin` partials.
    # * <tt>:model</tt> - Datagrid object to be rendedred.
    # * All options supported by Rails <tt>form_with</tt> helper
    # @param grid [Datagrid] grid object
    # @return [String] form HTML tag markup
    def datagrid_form_with(**options)
      if block_given?
        raise ArgumentError, 'datagrid_form_with block argument is invalid. Use form_with instead.'
      end
      datagrid_renderer.form_with(**options)
    end

    # Renders HTML for grid with all filters inputs and labels defined in it
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for form partial lookup.
    #   Default: 'datagrid'.
    # * All options supported by Rails <tt>form_for</tt> helper
    # @deprecated Use {#datagrid_form_with} instead.
    # @param grid [Datagrid] grid object
    # @return [String] form HTML tag markup
    def datagrid_form_for(grid, options = {})
      Datagrid::Utils.warn_once("datagrid_form_for is deprecated if favor of datagrid_form_with.")
      datagrid_renderer.form_for(grid, options)
    end

    # Provides access to datagrid columns data.
    # Used in case you want to build html table completelly manually
    # @param grid [Datagrid] grid object
    # @param asset [Object] object from grid scope
    # @param block [Proc] block with Datagrid::Helper::HtmlRow as an argument returning a HTML markup as a String
    # @return [Datagrid::Helper::HtmlRow, String] captured HTML markup if block given otherwise row object
    # @example
    #   # Suppose that grid has first_name and last_name columns
    #   <%= datagrid_row(grid, user) do |row| %>
    #     <tr>
    #       <td><%= row.first_name %></td>
    #       <td><%= row.last_name %></td>
    #     </tr>
    #   <% end %>
    # @example
    #   <% row = datagrid_row(grid, user) %>
    #   First Name: <%= row.first_name %>
    #   Last Name: <%= row.last_name %>
    # @example
    #   <%= datagrid_row(grid, user, columns: [:first_name, :last_name, :actions]) %>
    def datagrid_row(grid, asset, **options, &block)
      datagrid_renderer.row(grid, asset, **options, &block)
    end

    # Generates an ascending or descending order url for the given column
    # @param grid [Datagrid] grid object
    # @param column [Datagrid::Columns::Column, String, Symbol] column name
    # @param descending [Boolean] specifies order direction. Ascending if false, otherwise descending.
    # @return [String] order layout HTML markup
    def datagrid_order_path(grid, column, descending)
      datagrid_renderer.order_path(grid, column, descending, request)
    end

    protected

    def datagrid_renderer
      Renderer.for(self)
    end

    def datagrid_column_classes(grid, column)
      order_class = if grid.ordered_by?(column)
                      grid.descending ? "datagrid-order-active-desc" : "datagrid-order-active-asc"
                    end
      [order_class, column.html_class].compact.join(" ")
    end
  end
end
