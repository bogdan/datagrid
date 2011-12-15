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
      value = column.html? ? @template.instance_exec(asset, &column.block) : column.value(asset, grid)
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

    def table(grid, *args)
      options = args.extract_options!
      options[:html] ||= {}
      options[:html][:class] ||= "datagrid #{grid.class.to_s.underscore.demodulize}"
      assets = args.any? ? args.shift : grid.assets
      paginate = options[:paginate]
      assets = assets.paginate(paginate) if paginate 

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


    def _safe(string)
      string.respond_to?(:html_safe) ? string.html_safe : string
    end
  end
end
