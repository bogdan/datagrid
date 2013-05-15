require "action_view"

module Datagrid
  class Renderer

    def self.for(template)
      new(template)
    end

    def initialize(template)
      @template = template
    end

    def format_value(grid, column, asset)

      value = if column.html?
        args = []
        remaining_arity = column.html_block.arity

        if column.data?
          args << column.value(asset,grid)
          remaining_arity -= 1
        end

        args << asset if remaining_arity > 0
        args << grid if remaining_arity > 1

        @template.instance_exec(*args, &column.html_block)
      else
        column.value(asset,grid)
      end

      url = column.options[:url] && column.options[:url].call(asset)
      if url
        @template.link_to(value, url)
      else
        case column.format
        when :url
          @template.link_to(column.label  ? asset.send(column.label) : I18n.t("datagrid.table.url_label", :default => "URL"), value)
        else
          _safe(value)
        end
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
      assets = args.any? ? args.shift : grid.assets
      paginate = options[:paginate]
      if paginate
        ::Datagrid::Utils.warn_once(":paginate option is deprecated. Looks to https://github.com/bogdan/datagrid/wiki/Frontend.")
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
