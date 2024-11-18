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
      column = grid.column_by_name(column) if column.is_a?(String) || column.is_a?(Symbol)

      grid.html_value(column, self, model)
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
    # @param [Hash{Symbol => Object}] options HTML attributes to be passed to `<table>` tag
    # @return [String] table tag HTML markup
    # @example
    #   assets = grid.assets.page(params[:page])
    #   datagrid_table(grid, assets, options)
    def datagrid_table(grid, assets = grid.assets, **options)
      _render_partial(
        "table", options[:partials],
        {
          grid: grid,
          options: options,
          assets: assets,
        },
      )
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
    # @param [Hash] options
    # @return [String] HTML table header tag markup
    def datagrid_header(grid, opts = :__unspecified__, **options)
      unless opts == :__unspecified__
        Datagrid::Utils.warn_once("datagrid_header now requires ** operator when passing options.")
        options.reverse_merge!(opts)
      end
      options[:order] = true unless options.key?(:order)

      _render_partial("head", options[:partials],
        { grid: grid, options: options },)
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
      safe_join(
        assets.map do |asset|
          datagrid_row(grid, asset, **options, &block)
        end.to_a,
      )
    end

    # @return [String] renders ordering controls for the given column name
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for partials lookup.
    #   Default: 'datagrid'.
    def datagrid_order_for(grid, column, options = {})
      Datagrid::Utils.warn_once(<<~MSG)
        datagrid_order_for is deprecated.
        Put necessary code inline inside datagrid/head partial.
        See built-in partial for example.
      MSG
      _render_partial("order_for", options[:partials],
        { grid: grid, column: column },)
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
      raise ArgumentError, "datagrid_form_with block argument is invalid. Use form_with instead." if block_given?

      grid = options[:model]
      raise ArgumentError, "Grid has no available filters" if grid&.filters&.empty?

      _render_partial("form", options[:partials], { grid: options[:model], options: options })
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
    # @param [Hash] options
    # @return [String] form HTML tag markup
    def datagrid_form_for(grid, options = {})
      Datagrid::Utils.warn_once("datagrid_form_for is deprecated if favor of datagrid_form_with.")
      _render_partial(
        "form", options[:partials],
        grid: grid,
        options: {
          method: :get,
          as: grid.param_name,
          local: true,
          **options,
        },
      )
    end

    # Provides access to datagrid columns data.
    # Used in case you want to build html table completelly manually
    # @param grid [Datagrid] grid object
    # @param asset [Object] object from grid scope
    # @param block [Proc] block with Datagrid::Helper::HtmlRow as an argument returning a HTML markup as a String
    # @param [Hash{Symbol => Object}] options
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
      Datagrid::Helper::HtmlRow.new(self, grid, asset, options).tap do |row|
        return capture(row, &block) if block_given?
      end
    end

    # Generates an ascending or descending order url for the given column
    # @param grid [Datagrid] grid object
    # @param column [Datagrid::Columns::Column, String, Symbol] column name
    # @param descending [Boolean] order direction, descending if true, otherwise ascending.
    # @return [String] order layout HTML markup
    def datagrid_order_path(grid, column, descending)
      column = grid.column_by_name(column)
      query = request&.query_parameters || {}
      ActionDispatch::Http::URL.path_for(
        path: request&.path || "/",
        params: query.merge(grid.query_params(order: column.name, descending: descending)),
      )
    end

    # @!visibility private
    def datagrid_column_classes(grid, column)
      Datagrid::Utils.warn_once(<<~MSG)
        datagrid_column_classes is deprecated. Assign necessary classes manually.
        Correspond to default datagrid/rows partial for example.)
      MSG
      column = grid.column_by_name(column)
      order_class = if grid.ordered_by?(column)
                      ["ordered", grid.descending ? "desc" : "asc"]
                    end
      class_names(column.name, order_class, column.options[:class], column.tag_options[:class])
    end

    protected

    def _render_partial(partial_name, partials_path, locals = {})
      render({
        partial: File.join(partials_path || "datagrid", partial_name),
        locals: locals,
      })
    end

    # Represents a datagrid row that provides access to column values for the given asset
    # @example
    #   row = datagrid_row(grid, user)
    #   row.class      # => Datagrid::Helper::HtmlRow
    #   row.first_name # => "<strong>Bogdan</strong>"
    #   row.grid       # => Grid object
    #   row.asset      # => User object
    #   row.each do |value|
    #     puts value
    #   end
    class HtmlRow
      include Enumerable

      attr_reader :grid, :asset, :options

      # @!visibility private
      def initialize(renderer, grid, asset, options)
        @renderer = renderer
        @grid = grid
        @asset = asset
        @options = options
      end

      # @return [Object] a column value for given column name
      def get(column)
        @renderer.datagrid_value(@grid, column, @asset)
      end

      # Iterates over all column values that are available in the row
      # param block [Proc] column value iterator
      def each(&block)
        (@options[:columns] || @grid.html_columns).each do |column|
          block.call(get(column))
        end
      end

      # @return [String] HTML row format
      def to_s
        @renderer.send(:_render_partial, "row", options[:partials], {
          grid: grid,
          options: options,
          asset: asset,
        },)
      end

      protected

      def method_missing(method, *args, &blk)
        if (column = @grid.column_by_name(method))
          get(column)
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        !!@grid.column_by_name(method) || super
      end
    end
  end
end
