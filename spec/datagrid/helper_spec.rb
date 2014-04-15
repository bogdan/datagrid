require 'spec_helper'
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

require 'datagrid/renderer'

describe Datagrid::Helper do
  subject do
    template = ActionView::Base.new
    template.stub(:protect_against_forgery?).and_return(false)
    template.view_paths << File.expand_path("../../../app/views", __FILE__)
    template.view_paths << File.expand_path("../../support/test_partials", __FILE__)
    template
  end

  before(:each) do
    subject.stub(:params).and_return({})
    subject.stub(:url_for) do |options|
      options.to_param
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
      end
    end

    it "should show an empty table with dashes" do
      datagrid_table = subject.datagrid_table(grid)

      datagrid_table.should match_css_pattern(
        "table.datagrid tr td.noresults" => 1
      )
      datagrid_table.should include("&mdash;&mdash;")
    end
  end

  describe ".datagrid_table" do
    it "should have grid class as html class on table" do
      subject.datagrid_table(grid).should match_css_pattern(
        "table.datagrid.simple_report" => 1
      )
    end
    it "should have namespaced grid class as html class on table" do
      module ::Ns23
        class TestGrid
          include Datagrid
          scope { Entry }
        end
      end
      subject.datagrid_table(::Ns23::TestGrid.new).should match_css_pattern(
        "table.datagrid.ns23_test_grid" => 1
      )
    end
    it "should return data table html" do
      datagrid_table = subject.datagrid_table(grid)

      datagrid_table.should match_css_pattern({
        "table.datagrid tr th.group div.order" => 1,
        "table.datagrid tr th.group" => /Group.*/,
        "table.datagrid tr th.name div.order" => 1,
        "table.datagrid tr th.name" => /Name.*/,
        "table.datagrid tr td.group" => "Pop",
        "table.datagrid tr td.name" => "Star"
      })
    end

    it "should support giving assets explicitly" do
      other_entry = Entry.create!(entry.attributes)
      datagrid_table = subject.datagrid_table(grid, [entry])

      datagrid_table.should match_css_pattern({
        "table.datagrid tr th.group div.order" => 1,
        "table.datagrid tr th.group" => /Group.*/,
        "table.datagrid tr th.name div.order" => 1,
        "table.datagrid tr th.name" => /Name.*/,
        "table.datagrid tr td.group" => "Pop",
        "table.datagrid tr td.name" => "Star"
      })
    end

    it "should support cycle option" do
      subject.datagrid_rows(grid, [entry], :cycle => ["odd", "even"]).should match_css_pattern({
        "tr.odd td.group" => "Pop",
        "tr.odd td.name" => "Star"
      })

    end

    it "should support no order given" do
      subject.datagrid_table(grid, [entry], :order => false).should match_css_pattern("table.datagrid th .order" => 0)
    end

    it "should support columns option" do
      subject.datagrid_table(grid, [entry], :columns => [:name]).should match_css_pattern(
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
        subject.datagrid_table(grid, [entry]).should match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name" => 1,
          "table.datagrid th.category" => 0,
          "table.datagrid td.category" => 0
        )
      end
    end

    context "with html_attributes as a Hash" do
      let(:grid) do
        test_report do
          scope { Entry }
          column(:name, :html_attributes => {:rowspan => 2})
        end
      end

      it "should output only given column names" do
        subject.datagrid_table(grid, [entry]).should match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name[rowspan='2']" => 1
        )
      end
    end

    context "with html_attributes as a Proc" do
      let(:grid) do
        test_report do
          scope { Entry }
          column(:name, :html_attributes => lambda {|m| { "data-name" => m.name } })
        end
      end

      it "should output only given column names" do
        subject.datagrid_table(grid, [entry]).should match_css_pattern(
          "table.datagrid th.name" => 1,
          "table.datagrid td.name[data-name='Star']" => 1
        )
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


    describe ".datagrid_rows" do
      it "should support urls" do
        rp = test_report do
          scope { Entry }
          column(:name, :url => lambda {|model| model.name})
        end
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
          "tr td.name a[href=Star]" => "Star"
        )
      end

      it "should support conditional urls" do
        rp = test_report do
          scope { Entry }
          column(:name, :url => lambda {|model| false})
        end
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
          "tr td.name" => "Star"
        )
      end

      it "should add ordering classes to column" do
        rp = test_report(:order => :name) do
          scope { Entry }
          column(:name)
        end
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
          "tr td.name.ordered.asc" => "Star"
        )
      end

      it "should add ordering classes to column" do
        rp = test_report(:order => :name, :descending => true) do
          scope { Entry }
          column(:name)
        end
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
          "tr td.name span" => "Star"
        )
      end

      it "should render argument-based html columns" do
        rp = test_report do
          scope { Entry }
          column(:name, :html => lambda {|data| content_tag :h1, data})
        end
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
          "tr td.name h1" => "STAR-Star-Entry"
        )
      end

      it "should support columns option" do
        rp = test_report do
          scope { Entry }
          column(:name)
          column(:category)
        end
        subject.datagrid_rows(rp, [entry], :columns => [:name]).should match_css_pattern(
          "tr td.name" => "Star"
        )
        subject.datagrid_rows(rp, [entry], :columns => [:name]).should match_css_pattern(
          "tr td.category" => 0
        )
      end

      it "should allow CSS classes to be specified for a column" do
        rp = test_report do
          scope { Entry }
          column(:name, :class => 'my_class')
        end

        subject.datagrid_rows(rp, [entry]).should match_css_pattern(
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
          subject.datagrid_rows(grid, [entry]).should match_css_pattern(
            "td.name" => 1
          )
        end
      end
    end

    describe ".datagrid_order_for" do
      it "should render ordering layout" do
        class OrderedGrid
          include Datagrid
          scope { Entry }
          column(:category)
        end
        grid = OrderedGrid.new(:descending => true, :order => :category)
        subject.datagrid_order_for(grid, grid.column_by_name(:category)).should equal_to_dom(<<-HTML)
<div class="order">
  <a href="ordered_grid%5Bdescending%5D=false&amp;ordered_grid%5Border%5D=category" class="asc">&uarr;</a>
  <a href="ordered_grid%5Bdescending%5D=true&amp;ordered_grid%5Border%5D=category" class="desc">&darr;</a>
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
        grid = FormForGrid.new(:category => "hello")
        subject.datagrid_form_for(grid, :url => "/grid").should match_css_pattern(
          "form.datagrid-form.form_for_grid[action='/grid']" => 1,
          "form input[name=utf8]" => 1,
          "form .filter label" => "Category",
          "form .filter input.category.default_filter[name='form_for_grid[category]'][value=hello]" => 1,
          "form input[name=commit][value=Search]" => 1
        )
      end
      it "should support html classes for grid class with namespace" do
        module ::Ns22
          class TestGrid
            include Datagrid
            scope { Entry }
          end
        end
        subject.datagrid_form_for(::Ns22::TestGrid.new, :url => "grid").should match_css_pattern(
          "form.datagrid-form.ns22_test_grid" => 1,
        )
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
        r.name.should == "Hello"
        r.category.should == "greetings"
      end
      it "should yield block" do
        subject.datagrid_row(grid, entry) do |row|
          row.name.should == "Hello"
          row.category.should == "greetings"
        end
      end

      it "should output data from block" do
        name = subject.datagrid_row(grid, entry) do |row|
          subject.concat(row.name)
          subject.concat(",")
          subject.concat(row.category)
        end
        name.should == "Hello,greetings"
      end
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
      subject.datagrid_value(report, :name, entry).should == "<b>Star</b>"
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
      subject.datagrid_value(report, :name, entry).should == "<a href=\"/profile\">Star</a>"
    end
  end
end
