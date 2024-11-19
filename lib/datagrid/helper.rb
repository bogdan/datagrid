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
  # If you need a fully-featured custom GUI, create your templates manually with the help of the {Datagrid::Columns} API.
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
  #     = datagrid_form_for @grid, url: report_path, other_form_for_option: value
  #
  # {#datagrid_form_for} supports the same options as Rails `form_for`.
  #
  # ### Advanced Method
  #
  # You can use Rails built-in tools to create a form. Additionally, Datagrid provides helpers to generate input/select elements for filters:
  #
  # ``` haml
  # - form_for UserGrid.new, method: :get, url: users_path do |f|
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
  #     = datagrid_form_for @grid, html: {class: 'js-datagrid-form'}
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
  #     rake datagrid:copy_partials
  #
  # This creates files in `app/views/datagrid/`, which you can modify to suit your needs:
  #
  #     app/views/datagrid/
  #     ├── _enum_checkboxes.html.erb # datagrid_filter for filter(name, :enum, checkboxes: true)
  #     ├── _form.html.erb            # datagrid_form_for
  #     ├── _head.html.erb            # datagrid_header
  #     ├── _order_for.html.erb       # datagrid_order_for
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
  # The `:description` option is not built into Datagrid, but you can implement it by modifying the column header
  # partial `app/views/datagrid/_header.html.erb` like this:
  #
  #     %tr
  #       - grid.html_columns(*options[:columns]).each do |column|
  #         %th{class: datagrid_column_classes(grid, column)}
  #           = column.header
  #           - if column.options[:description]
  #             %a{data: {toggle: 'tooltip', title: column.options[:description]}}
  #               %i.icon-question-sign
  #           - if column.order && options[:order]
  #             = datagrid_order_for(grid, column, options)
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
  #     class IssuesGrid
  #       include Datagrid
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
    # @param [Hash{Symbol => Object}] options HTML attributes to be passed to `<table>` tag
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
    # @param [Hash] options
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

    # Renders HTML for for grid with all filters inputs and lables defined in it
    #
    # Supported options:
    #
    # * <tt>:partials</tt> - Path for form partial lookup.
    #   Default: 'datagrid'.
    # * All options supported by Rails <tt>form_for</tt> helper
    # @param grid [Datagrid] grid object
    # @param [Hash] options
    # @return [String] form HTML tag markup
    def datagrid_form_for(grid, options = {})
      datagrid_renderer.form_for(grid, options)
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
      datagrid_renderer.row(grid, asset, **options, &block)
    end

    # Generates an ascending or descending order url for the given column
    # @param grid [Datagrid] grid object
    # @param column [Datagrid::Columns::Column, String, Symbol] column name
    # @param descending [Boolean] order direction, descending if true, otherwise ascending.
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
                      ["ordered", grid.descending ? "desc" : "asc"]
                    end
      [column.name, order_class, column.options[:class]].compact.join(" ")
    end
  end
end
