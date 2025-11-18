# frozen_string_literal: true

require "action_view"

module Datagrid
  # # Datagrid Frontend Guide
  #
  # ## Description
  #
  # The easiest way to start with Datagrid frontend is by using the generator:
  #
  # ``` sh
  # rails generate datagrid:scaffold users
  # ```
  #
  # This command builds the controller, view, route, and adds
  # [built-in CSS](https://github.com/bogdan/datagrid/blob/master/app/assets/stylesheets/datagrid.sass).
  #
  # Datagrid includes helpers and a form builder for easy frontend generation.
  # If you need a fully-featured custom GUI, create your templates manually
  # with the help of the {Datagrid::Columns} API.
  #
  # ## Controller and Routing
  #
  # Grids usually implement the `index` action of a Rails REST resource. Here's an example:
  #
  #     resources :models, only: [:index]
  #
  # Use the `GET` method in the form, and the controller becomes straightforward:
  #
  #     class ModelsController < ApplicationController
  #       def index
  #         @grid = ModelsGrid.new(params[:my_report]) do |scope|
  #           scope.page(params[:page]) # See pagination section
  #         end
  #       end
  #     end
  #
  # To apply additional scoping conditions, such as visibility based on the current user:
  #
  #     ModelsGrid.new(params[:my_report]) do |scope|
  #       scope.where(owner_id: current_user.id).page(params[:page])
  #     end
  #
  # To pass an object to a grid instance, define it as an accessible attribute:
  #
  #     class ModelsGrid
  #       attr_accessor :current_user
  #     end
  #
  # Then pass it when initializing the grid:
  #
  #     ModelsGrid.new(params[:models_grid].merge(current_user: current_user))
  #
  # ## Form Builder
  #
  # ### Basic Method
  #
  # Use the built-in partial:
  #
  #     = datagrid_form_with model: @grid, url: report_path, other_form_for_option: value
  #
  # {#datagrid_form_with} supports the same options as Rails `form_with`.
  #
  # ### Advanced Method
  #
  # You can use Rails built-in tools to create a form.
  # Additionally, Datagrid provides helpers to generate input/select elements for filters:
  #
  # ``` haml
  # - form_with model: UserGrid.new, method: :get, url: users_path do |f|
  #   %div
  #     = f.datagrid_label :name
  #     = f.datagrid_filter :name # => <input name="grid[name]" type="text"/>
  #   %div
  #     = f.datagrid_label :category_id
  #     = f.datagrid_filter :category_id # => <select name="grid[category_id]">....</select>
  # ```
  #
  # For more flexibility, use Rails default helpers:
  #
  #     %div
  #       = f.label :name
  #       = f.text_field :name
  #
  # See the localization section of {Datagrid::Filters}.
  #
  # ## Datagrid Table
  #
  # Use the helper to display a report:
  #
  #     %div== Total #{@grid.assets.total}
  #     = datagrid_table(@report)
  #     = will_paginate @report.assets
  #
  # Options:
  #
  # - `:html` - Attributes for the `<table>` tag.
  # - `:order` - Set to `false` to disable ordering controls (default: `true`).
  # - `:columns` - Specify an array of column names to display.
  #
  # ## Pagination
  #
  # Datagrid is abstracted from pagination but integrates seamlessly with tools like Kaminari, WillPaginate, or Pagy:
  #
  #     # Kaminari
  #     @grid = MyGrid.new(params[:grid]) do |scope|
  #       scope.page(params[:page]).per(10)
  #     end
  #
  #     # WillPaginate
  #     @grid = MyGrid.new(params[:grid]) do |scope|
  #       scope.page(params[:page]).per_page(10)
  #     end
  #
  #     # Pagy
  #     @grid = MyGrid.new(params[:grid])
  #     @pagy, @records = pagy(@grid.assets)
  #
  # Render the paginated collection:
  #
  #     # WillPaginate or Kaminari
  #     <%= datagrid_table(@grid, options) %>
  #     # Pagy
  #     <%= datagrid_table(@grid, @records, options) %>
  #
  # ## CSV Export
  #
  # Add CSV support to your controller:
  #
  #     class UsersController < ApplicationController
  #       def index
  #         @grid = UsersGrid.new(params[:users_grid])
  #         respond_to do |f|
  #           f.html { @grid.scope { |scope| scope.page(params[:page]) } }
  #           f.csv do
  #             send_data @grid.to_csv, type: "text/csv", disposition: 'inline', filename: "grid-#{Time.now.to_s}.csv"
  #           end
  #         end
  #       end
  #     end
  #
  # Add a button in your interface:
  #
  #     link_to "Get CSV", url_for(format: 'csv', users_grid: params[:users_grid])
  #
  # ## AJAX
  #
  # Datagrid supports asynchronous data loading. Add this to your controller:
  #
  #     if request.xhr?
  #       render json: {table: view_context.datagrid_table(@grid)}
  #     end
  #
  # Modify the form for AJAX:
  #
  #     = datagrid_form_with model: @grid, html: {class: 'js-datagrid-form'}
  #     .js-datagrid-table
  #       = datagrid_table @grid
  #     .js-pagination
  #       = paginate @grid.assets
  #     :javascript
  #       $('.js-datagrid-form').submit(function(event) {
  #         event.preventDefault();
  #         $.get($(this).attr("action"), $(this).serialize(), function (data) {
  #           $('.js-datagrid-table').html(data.table);
  #         });
  #       });
  #
  # ## Modifying Built-In Partials
  #
  # To customize Datagrid views:
  #
  #     rails g datagrid:views
  #
  # This creates files in `app/views/datagrid/`, which you can modify to suit your needs:
  #
  #     app/views/datagrid/
  #     ├── _enum_checkboxes.html.erb # datagrid_filter for filter(name, :enum, checkboxes: true)
  #     ├── _form.html.erb            # datagrid_form_with
  #     ├── _head.html.erb            # datagrid_header
  #     ├── _range_filter.html.erb    # datagrid_filter for filter(name, type, range: true)
  #     ├── _row.html.erb             # datagrid_rows/datagrid_rows
  #     └── _table.html.erb           # datagrid_table
  #
  # ## Custom Options
  #
  # You can add custom options to Datagrid columns and filters and implement their support on the frontend.
  # For example, you might want to add a `description` option to a column that appears as a tooltip on mouseover.
  #
  #     column(
  #       :aov, header: 'AOV',
  #       description: 'Average order value: sum of orders subtotal divided by their count'
  #     ) do |category|
  #       category.orders.sum(:subtotal) / category.orders.count
  #     end
  #
  # The `:description` option is not built into Datagrid, but you can implement it
  # by adding the following to partial `app/views/datagrid/_header.html.erb`:
  #
  #     <% if column.options[:description] %>
  #       <a data-toggle="tooltip" title="<%= column.options[:description] %>">
  #         <i class="icon-question-sign"></i>
  #       </a>
  #     <% end %>
  #
  # This modification allows the `:description` tooltip to work with your chosen UI and JavaScript library.
  # The same technique can be applied to filters by calling `filter.options` in corresponding partials.
  #
  # ## Highlight Rows
  #
  # To add custom HTML classes to each row for styling, modify the `_row.html.erb` partial:
  #
  # ``` diff
  # -<tr>
  # +<tr class="<%= grid.respond_to?(:row_class) ? grid.row_class(asset) : "" %>">
  #    <% grid.html_columns(*options[:columns]).each do |column| %>
  #      <td class="<%= datagrid_column_classes(grid, column) %>">
  #        <%= datagrid_value(grid, column, asset) %>
  #      </td>
  #    <% end %>
  # ```
  #
  # This allows you to define a custom `row_class` method in your grid class, like this:
  #
  #     class IssuesGrid < ApplicationGrid
  #       scope { Issue }
  #
  #       def row_class(issue)
  #         case issue.status
  #         when "fixed" then "green"
  #         when "rejected" then "red"
  #         else "blue"
  #         end
  #       end
  #     end
  #
  # ## Localization
  #
  # You can overwrite Datagrid’s custom localization keys at the application level.
  # See the localization keys here:
  #
  # https://github.com/bogdan/datagrid/blob/master/lib/datagrid/locale/en.yml
  module Helper
    # @param grid [Datagrid::Base] grid object
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
    # @param grid [Datagrid::Base] grid object
    # @param assets [Array] objects from grid scope
    # @param [Hash{Symbol => Object}] options HTML attributes to be passed to `<table>` tag
    # @option options [Hash] html A hash of attributes for the `<table>` tag.
    # @option options [Boolean] order Whether to generate ordering controls.
    #   If set to `false`, ordering controls are not generated. Default: `true`.
    # @option options [Array<Symbol>] columns An array of column names to display.
    #   Use this when the same grid class is used in different contexts and requires different columns.
    #   Default: all defined columns.
    # @option options [String] partials The path for partials lookup. Default: `'datagrid'`.
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
    # @option options [Boolean] order Whether to display ordering controls built into the header.
    #   Default: `true`.
    # @option options [Array<Symbol,String>] columns An array of column names to display.
    #   Use this when the same grid class is used in different contexts and requires different columns.
    #   Default: all defined columns.
    # @option options [String] partials The path for partials lookup.
    #   Default: `'datagrid'`.
    # @param grid [Datagrid::Base] grid object
    # @param [Object] opts (deprecated) pass keyword arguments instead
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
    # @option options [Array<Symbol>] columns An array of column names to display.
    #   Use this when the same grid class is used in different contexts and requires different columns.
    #   Default: all defined columns.
    # @option options [String] partials The path for partials lookup.
    #   Default: `'datagrid'`.
    # @return [String]
    # @example Generic table rows Layout
    #   = datagrid_rows(grid)
    # @example Custom Layout
    #   = datagrid_rows(grid) do |row|
    #     %tr
    #       %td= row.project_name
    #       %td.project-status{class: row.status}= row.status
    # @param [Datagrid::Base] grid datagrid object
    # @param [Array<Object>] assets assets as per defined in grid scope
    def datagrid_rows(grid, assets = grid.assets, **options, &block)
      safe_join(
        assets.map do |asset|
          datagrid_row(grid, asset, **options, &block)
        end.to_a,
      )
    end

    # @return [String] renders ordering controls for the given column name
    # @option options [String] partials The path for partials lookup.
    #   Default: `'datagrid'`.
    # @param [Datagrid::Base] grid datagrid object
    # @param [Datagrid::Columns::Column] column
    # @deprecated Put necessary code inline inside datagrid/head partial.
    #   See built-in partial for example.
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
    # @option options [String] partials Path for form partial lookup.
    #   Default: `'datagrid'`, which uses `app/views/datagrid/` partials.
    #   Example: `'datagrid_admin'` uses `app/views/datagrid_admin` partials.
    # @option options [Datagrid::Base] model a Datagrid object to be rendered.
    # @option options [Hash] All options supported by Rails `form_with` helper.
    # @param [Hash{Symbol => Object}] options
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
    # * All options supported by Rails <tt>form_with</tt> helper
    # @deprecated Use {#datagrid_form_with} instead.
    # @param grid [Datagrid::Base] grid object
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
    # @param grid [Datagrid::Base] grid object
    # @param asset [Object] object from grid scope
    # @param block [Proc] block with Datagrid::Helper::HtmlRow as an argument returning a HTML markup as a String
    # @param [Hash{Symbol => Object}] options
    # @return [Datagrid::Helper::HtmlRow, String] captured HTML markup if block given otherwise row object
    # @example Render default layout for row
    #   <%= datagrid_row(grid, user, columns: [:first_name, :last_name, :actions]) %>
    # @example Rendering custom layout for `first_name` and `last_name` columns
    #   <%= datagrid_row(grid, user) do |row| %>
    #     <tr>
    #       <td><%= row.first_name %></td>
    #       <td><%= row.last_name %></td>
    #     </tr>
    #   <% end %>
    # @example Rendering custom layout passing a block
    #   <% row = datagrid_row(grid, user) %>
    #   First Name: <%= row.first_name %>
    #   Last Name: <%= row.last_name %>
    def datagrid_row(grid, asset, **options, &block)
      Datagrid::Helper::HtmlRow.new(self, grid, asset, options).tap do |row|
        return capture(row, &block) if block_given?
      end
    end

    # Generates an ascending or descending order url for the given column
    # @param grid [Datagrid::Base] grid object
    # @param column [Datagrid::Columns::Column, String, Symbol] column name
    # @param descending [Boolean] order direction, descending if true, otherwise ascending.
    # @return [String] order layout HTML markup
    def datagrid_order_path(grid, column, descending)
      column = grid.column_by_name(column)
      query = request&.query_parameters || {}
      ActionDispatch::Http::URL.path_for(
        path: request&.path || "/",
        params: query.merge(grid.query_params("order" => column.name, "descending" => descending)),
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
    #   row.grid       # => Datagrid::Base object
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
