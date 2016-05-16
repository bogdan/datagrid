require "datagrid/engine"
require "action_view"

module Datagrid
  module Helper

    # Returns individual cell value from the given grid, column name and model
    # Allows to render custom HTML layout for grid data
    #
    #   <ul>
    #     <% @grid.columns.each do |column|
    #       <li><%= column.header %>: <%= datagrid_value(@grid, column.name, @resource %></li>
    #     <% end %>
    #   </ul>
    #
    def datagrid_value(grid, column_name, model)
      datagrid_renderer.format_value(grid, column_name, model)
    end

    def datagrid_format_value(grid, column_name, model) #:nodoc:
      datagrid_value(grid, column_name, model)
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
    # * <tt>:columns</tt> - Array of column names to display.
    #   Used in case when same grid class is used in different places
    #   and needs different columns. Default: all defined columns.
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_table(grid, *args)
      datagrid_renderer.table(grid, *args)
    end

    # Renders HTML table header for given grid instance using columns defined in it
    #
    # Supported options:
    #
    # * <tt>:order</tt> - display ordering controls built-in into header
    #   Default: true
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_header(grid, options = {})
      datagrid_renderer.header(grid, options)
    end


    # Renders HTML table rows using given grid definition using columns defined in it
    #
    # Supported options:
    #
    # * <tt>:columns</tt> - Array of column names to display.
    #   Used in case when same grid class is used in different places
    #   and needs different columns. Default: all defined columns.
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_rows(grid, assets, options = {})
      datagrid_renderer.rows(grid, assets, options)
    end

    # Renders ordering controls for the given column name
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_order_for(grid, column, options = {})
      datagrid_renderer.order_for(grid, column, options)
    end

    # Renders HTML for for grid with all filters inputs and lables defined in it
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for form partial lookup.
    #   Default: 'datagrid'.
    # * All options supported by Rails <tt>form_for</tt> helper
    def datagrid_form_for(grid, options = {})
      datagrid_renderer.form_for(grid, options)
    end

    # Provides access to datagrid columns data.
    #
    #   # Suppose that <tt>grid</tt> has first_name and last_name columns
    #   <%= datagrid_row(grid, user) do |row| %>
    #     <tr>
    #       <td><%= row.first_name %></td>
    #       <td><%= row.last_name %></td>
    #     </tr>
    #   <% end %>
    #
    # Used in case you want to build html table completelly manually
    def datagrid_row(grid, asset, &block)
      HtmlRow.new(self, grid, asset).tap do |row|
        if block_given?
          return capture(row, &block)
        end
      end
    end

    # Represents a datagrid row that provides access to column values for the given asset
    #
    #   row = datagrid_row(grid, user)
    #   row.first_name # => "<strong>Bogdan</strong>"
    #   row.grid       # => Grid object
    #   row.asset      # => User object
    class HtmlRow

      attr_reader :grid, :asset

      def initialize(context, grid, asset) # :nodoc:
        @context = context
        @grid = grid
        @asset = asset
      end

      def method_missing(method, *args, &blk)
        if column = @grid.column_by_name(method)
          @context.datagrid_value(@grid, column, @asset)
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
      order_class = grid.ordered_by?(column) ? ["ordered", grid.descending ? "desc" : "asc"] : nil
      [column.name, order_class, column.options[:class]].compact.join(" ")
    end
  end
end

