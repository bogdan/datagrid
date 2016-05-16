require 'spec_helper'
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

require 'datagrid/renderer'

describe Datagrid::Helper do
  subject do
    template = ActionView::Base.new
    allow(template).to receive(:protect_against_forgery?).and_return(false)
    template.view_paths << File.expand_path("../../../app/views", __FILE__)
    template.view_paths << File.expand_path("../../support/test_partials", __FILE__)
    template
  end

  before(:each) do
    allow(subject).to receive(:params).and_return({})
    allow(subject).to receive(:url_for) do |options|
      options.is_a?(String) ? options : ["/location", options.to_param.presence].compact.join('?')
    end

  end

  let(:group) { Group.create!(:name => "Pop") }
  let!(:entry) {  Entry.create!(
    :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
  ) }
  let(:grid) { SimpleReport.new }

  context "when grid has no records" do
    let(:grid) do
      test_report do
        scope { Entry.where("1 != 1") }
        column(:id)
      end
    end

    it "should show an empty table with dashes" do
      datagrid_table = subject.datagrid_table(grid)

      expect(datagrid_table).to match_css_pattern(
        "table.datagrid tr td.noresults" => 1
      )
      expect(datagrid_table).to include("&mdash;&mdash;")
    end
  end

  describe ".datagrid_table" do
    it "should have grid class as html class on table" do
      expect(subject.datagrid_table(grid)).to match_css_pattern(
        "table.datagrid.simple_report" => 1
      )
    end
    it "should have namespaced grid class as html class on table" do
      module ::Ns23
        class TestGrid
          include Datagrid
          scope { Entry }
          column(:id)
        end
      end
      expect(subject.datagrid_table(::Ns23::TestGrid.new)).to match_css_pattern(
        "table.datagrid.ns23_test_grid" => 1
      )
    end
    it "should return data table html" do
      datagrid_table = subject.datagrid_table(grid)

      expect(datagrid_table).to match_css_pattern({
        "table.datagrid tr th.group div.order" => 1,
        "table.datagrid tr th.group" => /Group.*/,
        "table.datagrid tr th.name div.order" => 1,
        "table.datagrid tr th.name" => /Name.*/,
        "table.datagrid tr td.group" => "Pop",
        "table.datagrid tr td.name" => "Star"
      })
    end

    it "should support giving assets explicitly" do
      Entry.create!(entry.attributes)
      datagrid_table = subject.datagrid_table(grid, [entry])

      expect(datagrid_table).to match_css_pattern({
        "table.datagrid tr th.group div.order" => 1,
        "table.datagrid tr th.group" => /Group.*/,
        "table.datagrid tr th.name div.order" => 1,
        "table.datagrid tr th.name" => /Name.*/,
        "table.datagrid tr td.group" => "Pop",
        "table.datagrid tr td.name" => "Star"
      })
    end

    it "should support no order given" do
      expect(subject.datagrid_table(grid, [entry], :order => false)).to match_css_pattern("table.datagrid th .order" => 0)
    end

    it "should support columns option" do
      expect(subject.datagrid_table(grid, [entry], :columns => [:name])).to match_css_pattern(
        "table.datagrid th.name" => 1,
        "table.datagrid td.name" => 1,
        "table.datagrid th.group" => 0,
        "table.datagrid td.group" => 0
      )
    end

    context "with column_names attribute" do
      let(:grid) do
        test_report(:column_names => "name") do
          scope { Entry }
          column(:name)
          column(:category)
        end
      end

      it "should output only given column names" do
        expect(subject.datagrid_table(grid, [entry])).to match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name" => 1,
          "table.datagrid th.category" => 0,
          "table.datagrid td.category" => 0
        )
      end
    end

    context "when grid has no columns" do
      let(:grid) do
        test_report do
          scope {Entry}
        end
      end

      it "should render no_columns message" do
        expect(subject.datagrid_table(grid, [entry])).to equal_to_dom("No columns selected")
      end
    end

    context 'with partials attribute' do
      let(:grid) do
        test_report do
          scope { Entry }
          column(:name)
          column(:category)
        end
      end

      it 'renders namespaced table partial' do
        rendered_partial = subject.datagrid_table(grid, [entry], {
                                    :partials => 'client/datagrid'
                                    })
        expect(rendered_partial).to include 'Namespaced table partial.'
        expect(rendered_partial).to include 'Namespaced row partial.'
        expect(rendered_partial).to include 'Namespaced head partial.'
        expect(rendered_partial).to include 'Namespaced order_for partial.'
      end
    end

    context "when scope is enumerator" do
      let(:grid) do
        test_report do
          scope { ['a', 'b'].to_enum }
          column(:name) do |value|
            value
          end
        end
      end
      it "should render table" do
        expect(subject.datagrid_table(grid)).to match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name" => 2,
        )
      end
    end
    context "when scope is lazy enumerator" do
      before(:each) do
        pending("not supported by ruby < 2.0") if RUBY_VERSION < '2.0'
      end
      let(:grid) do
        test_report do
          scope { ['a', 'b'].lazy }
          column(:name) do |value|
            value
          end
        end
      end
      it "should render table" do
        expect(subject.datagrid_table(grid)).to match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name" => 2,
        )
      end
    end
  end

  describe ".datagrid_rows" do
    it "should support urls" do
      rp = test_report do
        scope { Entry }
        column(:name, :url => lambda {|model| model.name})
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name a[href=Star]" => "Star"
      )
    end

    it "should support conditional urls" do
      rp = test_report do
        scope { Entry }
        column(:name, :url => lambda {|model| false})
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name" => "Star"
      )
    end

    it "should add ordering classes to column" do
      rp = test_report(:order => :name) do
        scope { Entry }
        column(:name)
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name.ordered.asc" => "Star"
      )
    end

    it "should add ordering classes to column" do
      rp = test_report(:order => :name, :descending => true) do
        scope { Entry }
        column(:name)
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name.ordered.desc" => "Star"
      )
    end

    it "should render html columns" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => true) do |model|
          content_tag(:span, model.name)
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name span" => "Star"
      )
    end

    it "should render argument-based html columns" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda {|data| content_tag :h1, data})
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name h1" => "Star"
      )
    end

    it "should render argument-based html columns with custom data" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda {|data| content_tag :em, data}) do
          self.name.upcase
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name em" => "STAR"
      )
    end

    it "should render html columns with double arguments for column" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => true) do |model, grid|
          content_tag(:span, "#{model.name}-#{grid.assets.klass}" )
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name span" => "Star-Entry"
      )
    end

    it "should render argument-based html blocks with double arguments" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda { |data, model|
          content_tag :h1, "#{data}-#{model.name.downcase}"
        })
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name h1" => "Star-star"
      )
    end

    it "should render argument-based html blocks with triple arguments" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda { |data, model, grid|
          content_tag :h1, "#{data}-#{model.name.downcase}-#{grid.assets.klass}"
        })
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name h1" => "Star-star-Entry"
      )
    end

    it "should render argument-based html blocks with double arguments and custom data" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda { |data, model|
          content_tag :h1, "#{data}-#{model.name}"
        }) do
          self.name.upcase
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name h1" => "STAR-Star"
      )
    end

    it "should render argument-based html blocks with triple arguments and custom data" do
      rp = test_report do
        scope { Entry }
        column(:name, :html => lambda { |data, model, grid|
          content_tag :h1, "#{data}-#{model.name}-#{grid.assets.klass}"
        }) do
          self.name.upcase
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name h1" => "STAR-Star-Entry"
      )
    end

    it "should support columns option" do
      rp = test_report do
        scope { Entry }
        column(:name)
        column(:category)
      end
      expect(subject.datagrid_rows(rp, [entry], :columns => [:name])).to match_css_pattern(
        "tr td.name" => "Star"
      )
      expect(subject.datagrid_rows(rp, [entry], :columns => [:name])).to match_css_pattern(
        "tr td.category" => 0
      )
    end

    it "should allow CSS classes to be specified for a column" do
      rp = test_report do
        scope { Entry }
        column(:name, :class => 'my_class')
      end

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td.name.my_class" => "Star"
      )
    end

    context "when grid has complicated columns" do
      let(:grid) do
        test_report(:name => 'Hello') do
          scope {Entry}
          filter(:name)
          column(:name) do |model, grid|
            "'#{model.name}' filtered by '#{grid.name}'"
          end
        end
      end
      it "should ignore them" do
        expect(subject.datagrid_rows(grid, [entry])).to match_css_pattern(
          "td.name" => 1
        )
      end
    end

    it "should escape html" do
      entry.update_attributes!(:name => "<div>hello</div>")
      expect(subject.datagrid_rows(grid, [entry], :columns => [:name])).to equal_to_dom(<<-HTML)
       <tr><td class="name">&lt;div&gt;hello&lt;/div&gt;</td></tr>
        HTML
    end

    it "should not escape safe html" do
      entry.update_attributes!(:name => "<div>hello</div>")
      grid.column(:safe_name) do |model|
        model.name.html_safe
      end
      expect(subject.datagrid_rows(grid, [entry], :columns => [:safe_name])).to equal_to_dom(<<-HTML)
       <tr><td class="safe_name"><div>hello</div></td></tr>
        HTML

    end

  end

  describe ".datagrid_order_for" do
    it "should render ordering layout" do
      class OrderedGrid
        include Datagrid
        scope { Entry }
        column(:category)
      end
      object = OrderedGrid.new(:descending => true, :order => :category)
      expect(subject.datagrid_order_for(object, object.column_by_name(:category))).to equal_to_dom(<<-HTML)
<div class="order">
<a href="/location?ordered_grid%5Bdescending%5D=false&amp;ordered_grid%5Border%5D=category" class="asc">&uarr;</a>
<a href="/location?ordered_grid%5Bdescending%5D=true&amp;ordered_grid%5Border%5D=category" class="desc">&darr;</a>
</div>
      HTML
    end

  end
  describe ".datagrid_form_for" do
    it 'returns namespaced partial if partials options is passed' do
      rendered_form = subject.datagrid_form_for(grid, {
        :url => '',
        :partials => 'client/datagrid'
      })
      expect(rendered_form).to include 'Namespaced form partial.'
    end
    it "should render form and filter inputs" do
      class FormForGrid
        include Datagrid
        scope { Entry }
        filter(:category)
      end
      object = FormForGrid.new(:category => "hello")
      expect(subject.datagrid_form_for(object, :url => "/grid")).to match_css_pattern(
        "form.datagrid-form.form_for_grid[action='/grid']" => 1,
        "form input[name=utf8]" => 1,
        "form .filter label" => "Category",
        "form .filter input.category.default_filter[name='form_for_grid[category]'][value=hello]" => 1,
        "form input[name=commit][value=Search]" => 1,
        "form a.datagrid-reset[href='/location']" => 1
      )
    end
    it "should support html classes for grid class with namespace" do
      module ::Ns22
        class TestGrid
          include Datagrid
          scope { Entry }
          filter(:id)
        end
      end
      expect(subject.datagrid_form_for(::Ns22::TestGrid.new, :url => "grid")).to match_css_pattern(
        "form.datagrid-form.ns22_test_grid" => 1,
        "form.datagrid-form label[for=ns22_test_grid_id]" => 1,
        "form.datagrid-form input#ns22_test_grid_id[name='ns22_test_grid[id]']" => 1,
      )
    end

    it "should have overridable param_name method" do
      class ParamNameGrid81
        include Datagrid
        scope { Entry }
        filter(:id)
        def param_name
          'g'
        end
      end
      expect(subject.datagrid_form_for(::ParamNameGrid81.new, :url => "/grid")).to match_css_pattern(
        "form.datagrid-form input[name='g[id]']" => 1,
      )
    end

    it "takes default partials if custom doesn't exist" do
      class PartialDefaultGrid
        include Datagrid
        scope {Entry}
        filter(:id, :integer, :range => true)
        filter(:group_id, :enum, :multiple => true, :checkboxes => true, :select => [1,2])
        def param_name
          'g'
        end
      end
      rendered_form = subject.datagrid_form_for(PartialDefaultGrid.new, {
        :url => '',
        :partials => 'custom_form'
      })
      expect(rendered_form).to include 'form_partial_test'
      expect(rendered_form).to match_css_pattern([
        'input.integer_filter.from',
        'input.integer_filter.to',
        ".enum_filter input[value='1']",
        ".enum_filter input[value='2']",
      ])
    end
  end


  describe ".datagrid_row" do
    let(:grid) do
      test_report do
        scope { Entry }
        column(:name)
        column(:category)
      end
    end

    let(:entry) do
      Entry.create!(:name => "Hello", :category => "greetings")
    end

    it "should provide access to row data" do
      r = subject.datagrid_row(grid, entry)
      expect(r.name).to eq("Hello")
      expect(r.category).to eq("greetings")
    end

    it "should yield block" do
      subject.datagrid_row(grid, entry) do |row|
        expect(row.name).to eq("Hello")
        expect(row.category).to eq("greetings")
      end
    end

    it "should output data from block" do
      name = subject.datagrid_row(grid, entry) do |row|
        subject.concat(row.name)
        subject.concat(",")
        subject.concat(row.category)
      end
      expect(name).to eq("Hello,greetings")
    end

    it "should give access to grid and asset" do
      r = subject.datagrid_row(grid, entry)
      expect(r.grid).to eq(grid)
      expect(r.asset).to eq(entry)
    end

    it "should use cache" do
      grid = test_report do
        scope {Entry}
        self.cached = true
        column(:random1, html: true) {rand(10**9)}
        column(:random2) {|model| format(rand(10**9)) {|value| value}}
      end

      entry = Entry.create!

      data_row = grid.data_row(entry)
      html_row = subject.datagrid_row(grid, entry)
      expect(html_row.random1).to eq(html_row.random1)
      expect(html_row.random2).to_not eq(html_row.random1)
      expect(data_row.random2).to eq(html_row.random2)
      expect(data_row.random2).to_not eq(html_row.random1)
      grid.cached = false
      expect(html_row.random2).to_not eq(html_row.random2)
      expect(html_row.random2).to_not eq(html_row.random1)
      expect(data_row.random2).to_not eq(html_row.random2)
      expect(data_row.random2).to_not eq(html_row.random1)
    end

  end

  describe ".datagrid_value" do
    it "should format value by column name" do
      report = test_report do
        scope {Entry}
        column(:name) do |e|
          "<b>#{e.name}</b>"
        end
      end

      expect(subject.datagrid_value(report, :name, entry)).to eq("<b>Star</b>")
    end
    it "should support format in column" do
      report = test_report do
        scope {Entry}
        column(:name) do |e|
          format(e.name) do |value|
             link_to value, "/profile"
          end
        end
      end
      expect(subject.datagrid_value(report, :name, entry)).to be_html_safe
      expect(subject.datagrid_value(report, :name, entry)).to eq("<a href=\"/profile\">Star</a>")
    end

  end

  describe ".datagrid_header" do

    it "should support order_by_value colums" do
      grid = test_report(:order => "category") do
        scope { Entry }
        column(:category, :order => false, :order_by_value => true)

        def param_name
          'grid'
        end
      end
      expect(subject.datagrid_header(grid)).to equal_to_dom(<<HTML)
<tr><th class="category ordered asc">Category<div class="order">
<a href="/location?grid%5Bdescending%5D=false&amp;grid%5Border%5D=category" class="asc">&uarr;</a><a href="/location?grid%5Bdescending%5D=true&amp;grid%5Border%5D=category" class="desc">&darr;</a>
</div>
</th></tr>
HTML
    end
  end

end

