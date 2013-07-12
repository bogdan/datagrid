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

      value = column.html_value(@template, asset, grid)

      url = column.options[:url] && column.options[:url].call(asset)
      if url
        @template.link_to(value, url)
      else
        _safe(value)
      end
    end

    def form_for(grid, options = {})
      options[:method] ||= :get
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid-form #{html_class(grid)}"
      @template.render :partial => "datagrid/form", :locals => {:grid => grid, :options => options}
    end

    def table(grid, *args)
      options = args.extract_options!
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid #{html_class(grid)}"
      if options[:cycle]
        ::Datagrid::Utils.warn_once("datagrid_table cycle option is deprecated. Use css to stylee odd/even rows instead.")
      end
      assets = args.any? ? args.shift : grid.assets
      paginate = options[:paginate]
      if paginate
        ::Datagrid::Utils.warn_once(":paginate option is deprecated. Look to https://github.com/bogdan/datagrid/wiki/Frontend.")
        assets = assets.paginate(paginate)
      end

      @template.render :partial => "datagrid/table", :locals => {:grid => grid, :options => options, :assets => assets}
    end

    def header(grid, options = {})
      options[:order] = true unless options.has_key?(:order)

      @template.render :partial => "datagrid/head", :locals => {:grid => grid, :options => options}
    end

    def rows(grid, assets, options = {})
      result = assets.map do |asset|
        @template.render :partial => "datagrid/row", :locals => {:grid => grid, :options => options, :asset => asset}
      end.join

      _safe(result)
    end

    def order_for(grid, column)
      @template.render :partial => "datagrid/order_for", :locals => { :grid => grid, :column => column }
    end

    def html_class(grid)
      grid.class.to_s.underscore.demodulize
    end

    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end
  end
end
