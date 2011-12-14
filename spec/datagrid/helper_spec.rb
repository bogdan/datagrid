require 'spec_helper'
require "will_paginate"
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

  describe ".datagrid_table" do
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
          column(:name, :url => lambda {false})
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
    end

    describe ".datagrid_order_for" do
      it "should render ordreing layout" do
        class OrderedGrid
          include Datagrid
          scope { Entry }
          column(:category)
        end
        report = OrderedGrid.new(:descending => true, :order => :category)
        subject.datagrid_order_for(report, report.column_by_name(:category)).should equal_to_dom(<<-HTML)
<div class="order">
<a href="ordered_grid%5Bdescending%5D=false&amp;ordered_grid%5Border%5D=category" class="order asc">ASC</a> <a href="ordered_grid%5Bdescending%5D=true&amp;ordered_grid%5Border%5D=category" class="order desc">DESC</a>
</div>
        HTML
      end
    end
  end
end
