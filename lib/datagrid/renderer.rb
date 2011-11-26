require "action_view"

module Datagrid
  class Renderer

    def self.for(template)
      new(template)
    end

    def initialize(template)
      @template = template
    end

    def format_value(report, column, asset)
      value = column.value(asset, report)
      if column.options[:url]
        @template.link_to(value, column.options[:url].call(asset))
      else
        case column.format
        when :url
          @template.link_to(column.label  ? asset.send(column.label) : I18n.t("datagrid.table.url_label", :default => "URL"), value)
        else
          _safe(value)
        end
      end
    end

    def table(report, *args)
      options = args.extract_options!
      html = options[:html] || {}
      html[:class] ||= "datagrid"
      assets = args.any? ? args.shift : report.assets
      paginate = options[:paginate]
      assets = assets.paginate(paginate) if paginate 
      content = @template.content_tag(:tr, header(report, options)) + rows(report, assets, options)
      @template.content_tag(:table, content, html)
    end

    def header(grid, options = {})
      header = empty_string
      options[:order] = true unless options.has_key?(:order)
      grid.columns.each do |column|
        data = _safe(column.header)
        if options[:order] && column.order
          data << order_for(grid, column)
        end
        header << @template.content_tag(:th, data, :class => column.name)
      end
      header
    end

    def rows(report, assets, options)
      columns = report.columns
      result = assets.map do |asset|
        content = columns.map do |column|
          @template.content_tag(:td, format_value(report, column, asset), :class => column.name)
        end.join(empty_string)
        @template.content_tag(:tr, _safe(content), :class => options[:cycle] && @template.cycle(*options[:cycle]))
      end.join(empty_string)
      _safe(result)
    end

    def order_for(grid, column)
      @template.content_tag(:div, :class => "order") do
        @template.link_to(
          I18n.t("datagrid.table.order.asc", :default => "ASC"), 
          @template.url_for(grid.param_name => grid.attributes.merge(:order => column.name, :descending => false)),
          :class => "order asc"
        ) + " " + @template.link_to(
          I18n.t("datagrid.table.order.desc", :default => "DESC"),
          @template.url_for(grid.param_name => grid.attributes.merge(:order => column.name, :descending => true )),
          :class => "order desc"
        )
      end
    end

    def empty_string
      _safe("")
    end

    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end
  end
end
