module Datagrid
  module Helper

    def format_report_value(column, asset)
      value = column.value(asset)
      if column.options[:url]
        link_to(value, column.options[:url].call(asset))
      else
        case column.format
        when :url
          link_to(column.label  ? asset.send(column.label) : "URL", value)
        else
          value
        end
      end
    end

    def report_table(report, *args)
      options = args.extract_options!
      html = options[:html] || {}
      html[:class] ||= "standard-grid"
      paginate = options[:paginate] || {}
      paginate[:page] ||= params[:page]
      assets = report.assets.paginate(paginate)
      content_tag(:table, html) do
        table = content_tag(:tr, report_header(report, options))
        table << report_rows(report.columns, assets, options)
        table
      end
    end

    protected

    def report_header(report, options)
      header = empty_string
      report.columns.each do |column|
        data = column.header.html_safe
        if column.order
          data << content_tag(:div, :class => "order") do
            link_to("ASC", url_for(:report => report.attributes.merge(:order => column.order))) + " " +
              link_to("DESC", url_for(:report => report.attributes.merge(:order => column.desc_order)))
          end
        end
        header << content_tag(:th, data)
      end
      header
    end

    def report_rows(columns, assets, options)
      rows = empty_string
      assets.each do |asset|
        rows << content_tag(:tr) do
          html = empty_string
          columns.each do |column|
            html << content_tag(:td, format_report_value(column, asset), :class => cycle("odd", "even"))
          end
          html
        end

      end
      rows
    end

    def empty_string
      res = ""
      res.repond_to?(:html_safe) ? res.html_safe : res

    end
  end

  ::ActionView::Helpers.send(:include, ::Datagrid::Helper)

end
