require "action_view"

module Datagrid
  module Helper

    def datagrid_format_value(report, column, asset)
      value = column.value(asset, report)
      if column.options[:url]
        link_to(value, column.options[:url].call(asset))
      else
        case column.format
        when :url
          link_to(column.label  ? asset.send(column.label) : I18n.t("datagrid.table.url_label", :default => "URL"), value)
        else
          _safe(value)
        end
      end
    end

    def datagrid_table(report, *args)
      options = args.extract_options!
      html = options[:html] || {}
      html[:class] ||= "datagrid"
      assets = report.assets
      paginate = options[:paginate]
      assets = assets.paginate(paginate) if paginate 
      content = content_tag(:tr, datagrid_header(report, options)) + datagrid_rows(report, assets, options)
      content_tag(:table, content, html)
    end


    def datagrid_header(grid, options = {})
      header = empty_string
      options[:order] = true unless options.has_key?(:order)
      grid.columns.each do |column|
        data = _safe(column.header)
        if options[:order] && column.order
          data << datagrid_order_for(grid, column)
        end
        header << content_tag(:th, data)
      end
      header
    end

    def datagrid_rows(report, assets, options)
      columns = report.columns
      result = assets.map do |asset|
        content = columns.map do |column|
          content_tag(:td, datagrid_format_value(report, column, asset))
        end.join(empty_string)
        content_tag(:tr, _safe(content), :class => options[:cycle] && cycle(*options[:cycle]))
      end.join(empty_string)
      _safe(result)
    end

    def datagrid_order_for(grid, column)
      content_tag(:div, :class => "order") do
        link_to(
          I18n.t("datagrid.table.order.asc", :default => "ASC"), 
          url_for(grid.param_name => grid.attributes.merge(:order => column.name)),
          :class => "order asc"
        ) + " " + link_to(
          I18n.t("datagrid.table.order.desc", :default => "DESC"),
          url_for(grid.param_name => grid.attributes.merge(:order => column.name, :descending => true )),
          :class => "order desc"
        )
      end
    end

    protected
    def empty_string
      _safe("")
    end

    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end
  end

  ::ActionView::Base.send(:include, ::Datagrid::Helper)

end
