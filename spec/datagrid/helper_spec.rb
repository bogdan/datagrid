# frozen_string_literal: true

require "spec_helper"
require "active_support/core_ext/hash"
require "active_support/core_ext/object"
require "action_controller"

describe Datagrid::Helper do
  subject do
    action_view_template
  end

  before(:each) do
    allow(subject).to receive(:params).and_return({})
    allow(subject).to receive(:request) do
      Struct.new(:path, :query_parameters).new("/location", {})
    end
    allow(subject).to receive(:url_for) do |options|
      options.is_a?(String) ? options : ["/location", options.to_param.presence].compact.join("?")
    end

    # Rails defaults since 6.1
    ActionView::Helpers::FormHelper.form_with_generates_ids = true
    ActionView::Helpers::FormHelper.form_with_generates_remote_forms = false
    ActionView::Helpers::FormTagHelper.default_enforce_utf8 = false
  end

  let(:group) { Group.create!(name: "Pop") }
  let!(:entry) do
    Entry.create!(
      group: group, name: "Star", disabled: false, confirmed: false, category: "first",
    )
  end
  let(:grid) { SimpleReport.new }

  context "when grid has no records" do
    let(:grid) do
      test_grid do
        scope { Entry.where("1 != 1") }
        column(:id)
      end
    end

    it "should show an empty table with dashes" do
      datagrid_table = subject.datagrid_table(grid)

      expect(datagrid_table).to match_css_pattern(
        "table.datagrid-table tr td.datagrid-no-results" => 1,
      )
      expect(datagrid_table).to include(I18n.t("datagrid.no_results"))
    end
  end

  describe ".datagrid_table" do
    it "should have grid class as html class on table" do
      expect(subject.datagrid_table(grid)).to match_css_pattern(
        "table.datagrid-table" => 1,
      )
    end
    it "should return data table html" do
      datagrid_table = subject.datagrid_table(grid)

      expect(datagrid_table).to match_css_pattern({
        "table.datagrid-table tr th[data-column=group] div.datagrid-order" => 1,
        "table.datagrid-table tr th[data-column=group]" => %r{Group.*},
        "table.datagrid-table tr th[data-column=name] div.datagrid-order" => 1,
        "table.datagrid-table tr th[data-column=name]" => %r{Name.*},
        "table.datagrid-table tr td[data-column=group]" => "Pop",
        "table.datagrid-table tr td[data-column=name]" => "Star",
      })
    end

    it "should support giving assets explicitly" do
      Entry.create!(entry.attributes.except("id"))
      datagrid_table = subject.datagrid_table(grid, [entry])

      expect(datagrid_table).to match_css_pattern({
        "table.datagrid-table tr th[data-column=group] div.datagrid-order" => 1,
        "table.datagrid-table tr th[data-column=group]" => %r{Group.*},
        "table.datagrid-table tr th[data-column=name] div.datagrid-order" => 1,
        "table.datagrid-table tr th[data-column=name]" => %r{Name.*},
        "table.datagrid-table tr td[data-column=group]" => "Pop",
        "table.datagrid-table tr td[data-column=name]" => "Star",
      })
    end

    it "should support no order given" do
      expect(subject.datagrid_table(grid, [entry],
        order: false,)).to match_css_pattern("table.datagrid-table th .datagrid-order" => 0)
    end

    it "should support columns option" do
      expect(subject.datagrid_table(grid, [entry], columns: [:name])).to match_css_pattern(
        "table.datagrid-table th[data-column=name]" => 1,
        "table.datagrid-table td[data-column=name]" => 1,
        "table.datagrid-table th[data-column=group]" => 0,
        "table.datagrid-table td[data-column=group]" => 0,
      )
    end

    context "with column_names attribute" do
      let(:grid) do
        test_grid(column_names: "name") do
          scope { Entry }
          column(:name)
          column(:category)
        end
      end

      it "should output only given column names" do
        expect(subject.datagrid_table(grid, [entry])).to match_css_pattern(
          "table.datagrid-table th[data-column=name]" => 1,
          "table.datagrid-table td[data-column=name]" => 1,
          "table.datagrid-table th[data-column=category]" => 0,
          "table.datagrid-table td[data-column=category]" => 0,
        )
      end
    end

    context "when grid has no columns" do
      let(:grid) do
        test_grid
      end

      it "should render no_columns message" do
        expect(subject.datagrid_table(grid, [entry])).to equal_to_dom("No columns selected")
      end
    end

    context "with partials attribute" do
      let(:grid) do
        test_grid do
          scope { Entry }
          column(:name)
          column(:category)
        end
      end

      it "renders namespaced table partial" do
        rendered_partial = subject.datagrid_table(
          grid, [entry], partials: "client/datagrid",
        )
        expect(rendered_partial).to include "Namespaced table partial."
        expect(rendered_partial).to include "Namespaced row partial."
        expect(rendered_partial).to include "Namespaced head partial."
      end
    end

    context "when scope is enumerator" do
      let(:grid) do
        test_grid do
          scope { %w[a b].to_enum }
          column(:name) do |value|
            value
          end
        end
      end
      it "should render table" do
        expect(subject.datagrid_table(grid)).to match_css_pattern(
          "table.datagrid-table th[data-column=name]" => 1,
          "table.datagrid-table td[data-column=name]" => 2,
        )
      end
    end
    context "when scope is lazy enumerator" do
      let(:grid) do
        test_grid do
          scope { %w[a b].lazy }
          column(:name) do |value|
            value
          end
        end
      end
      it "should render table" do
        expect(subject.datagrid_table(grid)).to match_css_pattern(
          "table.datagrid-table th[data-column=name]" => 1,
          "table.datagrid-table td[data-column=name]" => 2,
        )
      end
    end
  end

  describe ".datagrid_rows" do
    it "should add ordering classes to column" do
      rp = test_grid_column(:name)
      rp.order = :name

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name].datagrid-order-active-asc" => "Star",
      )
    end
    it "should add ordering classes to column" do
      rp = test_grid_column(:name)
      rp.order = :name

      expect(
        subject.datagrid_rows(rp) do |row|
          subject.tag.strong(row.name)
        end,
      ).to match_css_pattern(
        "strong" => "Star",
      )
    end

    it "should add ordering classes to column" do
      rp = test_grid_column(:name)
      rp.order = :name
      rp.descending = true

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name].datagrid-order-active-desc" => "Star",
      )
    end

    it "should render columns with &:symbol block" do
      rp = test_grid_column(:name, &:name)

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name]" => "Star",
      )
    end

    it "should render html columns" do
      rp = test_grid_column(:name, html: true) do |model|
        tag.span(model.name)
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] span" => "Star",
      )
    end

    it "should render :html columns with &:symbol block" do
      rp = test_grid_column(:name, html: true, &:name)

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name]" => "Star",
      )
    end

    it "should render format columns with &:symbol block" do
      rp = test_grid do
        scope { Entry }
        column(:name) do |record|
          format(record, &:name)
        end
      end

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name]" => "Star",
      )
    end

    it "should render :html columns with &:symbol block with a data attribute" do
      rp = test_grid_column(:name, html: true, data: "DATA", &:name)

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name]" => "Star",
      )
    end

    it "should render argument-based html columns" do
      rp = test_grid_column(:name, html: ->(data) { tag.h1 data })
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] h1" => "Star",
      )
    end

    it "should render argument-based html columns with custom data" do
      rp = test_grid_column(:name, html: ->(data) { tag.em data }) do
        name.upcase
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] em" => "STAR",
      )
    end

    it "should render html columns with double arguments for column" do
      rp = test_grid_column(:name, html: true) do |model, grid|
        tag.span("#{model.name}-#{grid.assets.klass}")
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] span" => "Star-Entry",
      )
    end

    it "should render argument-based html blocks with double arguments" do
      rp = test_grid_column(:name, html: lambda { |data, model|
        tag.h1 "#{data}-#{model.name.downcase}"
      })
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] h1" => "Star-star",
      )
    end

    it "should render argument-based html blocks with triple arguments" do
      rp = test_grid_column(:name, html: lambda { |data, model, grid|
        content_tag :h1, "#{data}-#{model.name.downcase}-#{grid.assets.klass}"
      })
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] h1" => "Star-star-Entry",
      )
    end

    it "should render argument-based html blocks with double arguments and custom data" do
      rp = test_grid_column(:name, html: lambda { |data, model|
        content_tag :h1, "#{data}-#{model.name}"
      }) do
        name.upcase
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] h1" => "STAR-Star",
      )
    end

    it "should render argument-based html blocks with triple arguments and custom data" do
      rp = test_grid do
        scope { Entry }
        column(:name, html: lambda { |data, model, grid|
          content_tag :h1, "#{data}-#{model.name}-#{grid.assets.klass}"
        },) do
          name.upcase
        end
      end
      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name] h1" => "STAR-Star-Entry",
      )
    end

    it "should support columns option" do
      rp = test_grid do
        scope { Entry }
        column(:name)
        column(:category)
      end
      expect(subject.datagrid_rows(rp, [entry], columns: [:name])).to match_css_pattern(
        "tr td[data-column=name]" => "Star",
      )
      expect(subject.datagrid_rows(rp, [entry], columns: [:name])).to match_css_pattern(
        "tr td[data-column=category]" => 0,
      )
    end

    it "should allow CSS classes to be specified for a column" do
      rp = expect_deprecated do
        test_grid_column(:name, class: "my-class")
      end

      expect(subject.datagrid_rows(rp, [entry])).to match_css_pattern(
        "tr td[data-column=name].my-class" => "Star",
      )
    end

    it "supports tag_options option" do
      report = test_grid(order: :name, descending: true) do
        scope { Entry }
        column(:name, tag_options: {
          class: 'my-class',
          "data-column-group": "core",
          "data-column": nil,
        })
      end

      expect(subject.datagrid_rows(report, [entry])).to equal_to_dom(<<~HTML)
        <tr>
          <td class="my-class datagrid-order-active-desc" data-column-group="core">Star</td>
        </tr>
       HTML
    end

    context "when grid has complicated columns" do
      let(:grid) do
        test_grid(name: "Hello") do
          scope { Entry }
          filter(:name)
          column(:name) do |model, grid|
            "'#{model.name}' filtered by '#{grid.name}'"
          end
        end
      end
      it "should ignore them" do
        expect(subject.datagrid_rows(grid, [entry])).to match_css_pattern(
          "td[data-column=name]" => 1,
        )
      end
    end

    it "should escape html" do
      entry.update!(name: "<div>hello</div>")
      expect(subject.datagrid_rows(grid, [entry], columns: [:name])).to equal_to_dom(<<-HTML)
       <tr><td class="" data-column="name">&lt;div&gt;hello&lt;/div&gt;</td></tr>
      HTML
    end

    it "should not escape safe html" do
      entry.update!(name: "<div>hello</div>")
      grid.column(:safe_name) do |model|
        model.name.html_safe
      end
      expect(subject.datagrid_rows(grid, [entry], columns: [:safe_name])).to equal_to_dom(<<-HTML)
       <tr><td class="" data-column="safe_name"><div>hello</div></td></tr>
      HTML
    end
  end

  describe ".datagrid_order_for" do
    it "should render ordering layout" do
      class OrderedGrid < Datagrid::Base
        scope { Entry }
        column(:category)
      end
      object = OrderedGrid.new(descending: true, order: :category)
      silence_deprecator do
        expect(subject.datagrid_order_for(object, object.column_by_name(:category))).to equal_to_dom(<<~HTML)
          <div class="order">
          <a class="asc" href="/location?ordered_grid%5Bdescending%5D=false&amp;ordered_grid%5Border%5D=category">&uarr;</a>
          <a class="desc" href="/location?ordered_grid%5Bdescending%5D=true&amp;ordered_grid%5Border%5D=category">&darr;</a>
          </div>
        HTML
      end
    end
  end

  describe ".datagrid_form_for" do
    around(:each) do |e|
      silence_deprecator do
        e.run
      end
    end

    it "returns namespaced partial if partials options is passed" do
      rendered_form = subject.datagrid_form_for(grid, {
        url: "",
        partials: "client/datagrid",
      },)
      expect(rendered_form).to include "Namespaced form partial."
    end
    it "should render form and filter inputs" do
      class FormForGrid < Datagrid::Base
        scope { Entry }
        filter(:category, :string)
      end
      object = FormForGrid.new(category: "hello")
      expect(subject.datagrid_form_for(object, url: "/grid")).to equal_to_dom(<<~HTML)
         <form class="datagrid-form" action="/grid" accept-charset="UTF-8" method="get">
          <div class="datagrid-filter" data-filter="category" data-type="string">
            <label for="form_for_grid_category">Category</label>
            <input value="hello" type="text" name="form_for_grid[category]" id="form_for_grid_category" />
          </div>
          <div class="datagrid-actions">
            <input type="submit" name="commit" value="Search" class="datagrid-submit" data-disable-with="Search" />
            <a class="datagrid-reset" href="/location">Reset</a>
          </div>
        </form>
      HTML
    end
    it "should support html classes for grid class with namespace" do
      module ::Ns22
        class TestGrid < Datagrid::Base
          scope { Entry }
          filter(:id)
        end
      end
      expect(subject.datagrid_form_for(Ns22::TestGrid.new, url: "grid")).to match_css_pattern(
        "form.datagrid-form" => 1,
        "form.datagrid-form label[for=ns22_test_grid_id]" => 1,
        "form.datagrid-form input#ns22_test_grid_id[name='ns22_test_grid[id]']" => 1,
      )
    end

    it "should have overridable param_name method" do
      class ParamNameGrid81 < Datagrid::Base
        scope { Entry }
        filter(:id)
        def param_name
          "g"
        end
      end
      expect(subject.datagrid_form_for(ParamNameGrid81.new, url: "/grid")).to match_css_pattern(
        "form.datagrid-form input[name='g[id]']" => 1,
      )
    end

    it "takes default partials if custom doesn't exist" do
      class PartialDefaultGrid < Datagrid::Base
        scope { Entry }
        filter(:id, :integer, range: true)
        filter(:group_id, :enum, multiple: true, checkboxes: true, select: [1, 2])
        def param_name
          "g"
        end
      end
      rendered_form = subject.datagrid_form_for(PartialDefaultGrid.new, {
        url: "",
        partials: "custom_form",
      },)
      expect(rendered_form).to include "form_partial_test"
    end
  end

  describe ".datagrid_form_with" do
    it "returns namespaced partial if partials options is passed" do
      rendered_form = subject.datagrid_form_with(
        model: grid,
        url: "",
        partials: "client/datagrid",
      )
      expect(rendered_form).to include "Namespaced form partial."
    end
    it "should render form and filter inputs" do
      class FormWithGrid < Datagrid::Base
        scope { Entry }
        filter(:category, :string)
      end
      object = FormWithGrid.new(category: "hello")
      expect(subject.datagrid_form_with(model: object, url: "/grid")).to equal_to_dom(<<~HTML)
         <form class="datagrid-form" action="/grid" accept-charset="UTF-8" method="get">
          <div class="datagrid-filter" data-filter="category" data-type="string">
            <label for="form_with_grid_category">Category</label>
            <input value="hello" type="text" name="form_with_grid[category]" id="form_with_grid_category" />
          </div>
          <div class="datagrid-actions">
            <input type="submit" name="commit" value="Search" class="datagrid-submit" data-disable-with="Search" />
            <a class="datagrid-reset" href="/location">Reset</a>
          </div>
        </form>
      HTML
    end
    it "should support html classes for grid class with namespace" do
      module ::Ns23
        class TestGrid < Datagrid::Base
          scope { Entry }
          filter(:id)
        end
      end
      expect(subject.datagrid_form_with(model: Ns23::TestGrid.new, url: "grid")).to match_css_pattern(
        "form.datagrid-form" => 1,
        "form.datagrid-form label[for=ns23_test_grid_id]" => 1,
        "form.datagrid-form input#ns23_test_grid_id[name='ns23_test_grid[id]']" => 1,
      )
    end

    it "should have overridable param_name method" do
      class ParamNameGrid82 < Datagrid::Base
        scope { Entry }
        filter(:id)
        def param_name
          "g"
        end
      end
      expect(subject.datagrid_form_with(model: ParamNameGrid82.new, url: "/grid")).to match_css_pattern(
        "form.datagrid-form input[name='g[id]']" => 1,
      )
    end

    it "takes default partials if custom doesn't exist" do
      class PartialDefaultGrid < Datagrid::Base
        scope { Entry }
        filter(:id, :integer, range: true)
        filter(:group_id, :enum, multiple: true, checkboxes: true, select: [1, 2])
        def param_name
          "g"
        end
      end
      rendered_form = subject.datagrid_form_with(
        model: PartialDefaultGrid.new,
        url: "",
        partials: "custom_form",
      )
      expect(rendered_form).to include "form_partial_test"
    end
  end

  describe ".datagrid_row" do
    let(:grid) do
      test_grid do
        scope { Entry }
        column(:name)
        column(:category)
      end
    end

    let(:entry) do
      Entry.create!(name: "Hello", category: "greetings")
    end

    it "should provide access to row data" do
      r = subject.datagrid_row(grid, entry)
      expect(r.name).to eq("Hello")
      expect(r.category).to eq("greetings")
    end
    it "should provide an interator" do
      r = subject.datagrid_row(grid, entry)
      expect(r.map(&:upcase)).to eq(%w[HELLO GREETINGS])
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
      grid = test_grid do
        scope { Entry }
        self.cached = true
        column(:random1, html: true) { rand(10**9) }
        column(:random2) { |_model| format(rand(10**9)) { |value| value } }
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

    it "converts to string using columns option" do
      r = subject.datagrid_row(grid, entry, columns: [:name]).to_s
      expect(r).to match_css_pattern("tr td[data-column=name]")
      expect(r).to_not match_css_pattern("tr td.category")
    end
  end

  describe ".datagrid_value" do
    it "should format value by column name" do
      report = test_grid do
        scope { Entry }
        column(:name) do |e|
          "<b>#{e.name}</b>"
        end
      end

      expect(subject.datagrid_value(report, :name, entry)).to eq("<b>Star</b>")
    end
    it "should support format in column" do
      report = test_grid do
        scope { Entry }
        column(:name) do |e|
          format(e.name) do |value|
            link_to value, "/profile"
          end
        end
      end
      expect(subject.datagrid_value(report, :name, entry)).to be_html_safe
      expect(subject.datagrid_value(report, :name, entry)).to eq('<a href="/profile">Star</a>')
    end

    it "applies decorator" do
      report = test_grid do
        scope { Entry }
        decorate do |_model|
          Class.new(Struct.new(:model)) do
            def name
              model.name.upcase
            end
          end
        end
        column(:name, html: true)
      end
      entry = Entry.create!(name: "hello")
      expect(subject.datagrid_value(report, :name, entry)).to eq("HELLO")
    end
  end

  describe ".datagrid_header" do
    it "should support order_by_value colums" do
      grid = test_grid(order: "category") do
        scope { Entry }
        column(:category, order: false, order_by_value: true)

        def param_name
          "grid"
        end
      end
      expect(subject.datagrid_header(grid)).to equal_to_dom(<<~HTML)
        <tr><th class="datagrid-order-active-asc" data-column="category">Category<div class="datagrid-order">
        <a class="datagrid-order-control-asc" href="/location?grid%5Bdescending%5D=false&amp;grid%5Border%5D=category">&uarr;</a><a class="datagrid-order-control-desc" href="/location?grid%5Bdescending%5D=true&amp;grid%5Border%5D=category">&darr;</a>
        </div>
        </th></tr>
      HTML
    end

    it "supports tag_options option" do
      grid = test_grid(order: :name, descending: true) do
        scope { Entry }
        column(:name, order: false, tag_options: {
          class: 'my-class',
          "data-column-group": "core",
          "data-column": nil,
        })
      end

      expect(subject.datagrid_header(grid)).to equal_to_dom(<<~HTML)
        <tr>
          <th class="my-class datagrid-order-active-desc" data-column-group="core">Name</th>
        </tr>
       HTML
    end

    it "supports deprecated options passing" do
      grid = test_grid_column(:name)
      silence_deprecator do
        expect(
          subject.datagrid_header(grid, {order: false})
        ).to equal_to_dom(<<~HTML)
        <tr>
          <th data-column="name" class="">
            Name
          </th>
        </tr>
        HTML
      end
    end
  end

  describe ".datagrid_column_classes" do
    it "is deprecated" do
      grid = test_grid(order: :name, descending: true) do
        scope { Entry }
        column(:name)
        column(:category, tag_options: { class: "long-column" })
        column(:group_id, class: "short-column")
      end
      silence_deprecator do
        expect(subject.datagrid_column_classes(grid, :name)).to eq(
          "name ordered desc",
        )
        expect(subject.datagrid_column_classes(grid, :category)).to eq(
          "category long-column",
        )
        expect(subject.datagrid_column_classes(grid, :group_id)).to eq(
          "group_id short-column",
        )
      end
    end
  end
end
