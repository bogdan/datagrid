require 'spec_helper'
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

require 'datagrid/renderer'

describe Datagrid::Helper do
  subject do
    template = ActionView::Base.new
    template.view_paths << File.expand_path("../../../app/views", __FILE__)
    template.view_paths << File.expand_path("../../support/test_partials", __FILE__)
    template
  end

  before(:each) do
    subject.stub!(:params).and_return({})
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
    end
  end

  describe ".datagrid_table" do
    it "should have grid class as html class on table" do
      subject.datagrid_table(grid).should match_css_pattern(
        "table.datagrid.simple_report" => 1
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
<a href="ordered_grid%5Bdescending%5D=false&amp;ordered_grid%5Border%5D=category" class="order asc">&uarr;</a> <a href="ordered_grid%5Bdescending%5D=true&amp;ordered_grid%5Border%5D=category" class="order desc">&darr;</a>
</div>
        HTML
      end
    end
  end
end
