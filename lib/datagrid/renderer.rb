require "action_view"

module Datagrid
  # @!visibility private
  class Renderer

    def self.for(template)
      new(template)
    end

    def initialize(template)
      @template = template
    end

    def format_value(grid, column, asset)
      if column.is_a?(String) || column.is_a?(Symbol)
        column = grid.column_by_name(column)
      end

      value = grid.html_value(column, @template, asset)

      url = column.options[:url] && column.options[:url].call(asset)
      if url
        @template.link_to(value, url)
      else
        value
      end
    end

    def form_for(grid, options = {})
      options[:method] ||= :get
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid-form #{@template.dom_class(grid)}"
      options[:as] ||= grid.param_name
      _render_partial('form', options[:partials], {:grid => grid, :options => options})
    end

    def table(grid, assets, **options)
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid #{@template.dom_class(grid)}"

      _render_partial('table', options[:partials],
                      {
                        grid: grid,
                        options: options,
                        assets: assets
                      })
    end

    def header(grid, options = {})
      options[:order] = true unless options.has_key?(:order)

      _render_partial('head', options[:partials],
                      { :grid => grid, :options => options })
    end

    def rows(grid, assets = grid.assets, **options, &block)
      result = assets.map do |asset|
        row(grid, asset, **options, &block)
      end.to_a.join

      _safe(result)
    end

    def row(grid, asset, **options, &block)
      Datagrid::Helper::HtmlRow.new(self, grid, asset, options).tap do |row|
        if block_given?
          return @template.capture(row, &block)
        end
      end
    end

    def order_for(grid, column, options = {})
      _render_partial('order_for', options[:partials],
                      { :grid => grid, :column => column })
    end

    def order_path(grid, column, descending, request)
      column = grid.column_by_name(column)
      query = request ? request.query_parameters : {}
      ActionDispatch::Http::URL.path_for(
        path: request ? request.path : '/',
        params: query.merge(grid.query_params(order: column.name, descending: descending))
      )
    end

    private

    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end

    def _render_partial(partial_name, partials_path, locals = {})
      @template.render({
        :partial => File.join(partials_path || 'datagrid', partial_name),
        :locals => locals
      })
    end
  end

  module Helper
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
        @renderer.format_value(@grid, column, @asset)
      end

      # Iterates over all column values that are available in the row
      # param block [Proc] column value iterator
      def each(&block)
        (@options[:columns] || @grid.html_columns).each do |column|
          block.call(get(column))
        end
      end

      def to_s
        @renderer.send(:_render_partial, 'row', options[:partials], {
          :grid => grid,
          :options => options,
          :asset => asset
        })
      end

      protected
      def method_missing(method, *args, &blk)
        if column = @grid.column_by_name(method)
          get(column)
        else
          super
        end
      end
    end
  end
end
