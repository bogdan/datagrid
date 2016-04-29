require "action_view"

module Datagrid
  class Renderer #:nodoc:

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

    def table(grid, *args)
      options = args.extract_options!
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid #{@template.dom_class(grid)}"
      assets = args.any? ? args.shift : grid.assets

      _render_partial('table', options[:partials],
                      {
                        :grid => grid,
                        :options => options,
                        :assets => assets
                      })
    end

    def header(grid, options = {})
      options[:order] = true unless options.has_key?(:order)

      _render_partial('head', options[:partials],
                      { :grid => grid, :options => options })
    end

    def rows(grid, assets, options = {})
      result = assets.map do |asset|
        _render_partial(
          'row', options[:partials],
          {
            :grid => grid,
            :options => options,
            :asset => asset
          })
      end.to_a.join

      _safe(result)
    end

    def order_for(grid, column, options = {})
      _render_partial('order_for', options[:partials],
                      { :grid => grid, :column => column })
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
end
