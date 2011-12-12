require 'spec_helper'
require "will_paginate"
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

describe Datagrid::Helper do
  subject {ActionView::Base.new("spec/support")}

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
    before(:each) do
      subject.stub!(:datagrid_order_for).and_return(subject.content_tag(:div, "", :class => "order"))
    end
    it "should return data table html" do
      subject.datagrid_table(grid).should equal_to_dom(<<-HTML)
<table class="datagrid simple_report">
<tr>
<th class="group">Group<div class="order"></div>
</th>
<th class="name">Name<div class="order"></div>
</th>
<th class="actions">Actions</th>
</tr>

<tr>
<td class="group">Pop</td>
<td class="name">Star</td>
<td class="actions">No action for Star</td>
</tr>
</table>
HTML
    end
    it "should support giving assets explicitly" do
      other_entry = Entry.create!(entry.attributes)
      subject.datagrid_table(grid, [entry], :order => false).should equal_to_dom(<<-HTML)
<table class="datagrid simple_report">
<tr>
<th class="group">Group</th>
<th class="name">Name</th>
<th class="actions">Actions</th>
</tr>
</tr>

<tr>
<td class="group">Pop</td>
<td class="name">Star</td>
<td class="actions">No action for Star</td>
</tr>
</table>
HTML
    end

    describe ".datagrid_rows" do
      it "should support cycle option" do
        subject.datagrid_rows(grid, [entry], :cycle => ["odd", "even"]).should equal_to_dom(<<-HTML)
<tr class="odd">
<td class="group">Pop</td>
<td class="name">Star</td>
<td class="actions">No action for Star</td>
</tr>
HTML
      end

      it "should support urls" do
        rp = test_report do
          scope { Entry }
          column(:name, :url => lambda {|model| model.name})
        end
        subject.datagrid_rows(rp, [entry]).should equal_to_dom(<<-HTML)
  <tr><td class="name"><a href="Star">Star</a></td></tr>
  HTML
      end
      it "should support conditional urls" do
        rp = test_report do
          scope { Entry }
          column(:name, :url => lambda {false})
        end
        subject.datagrid_rows(rp, [entry]).should equal_to_dom(<<-HTML)
  <tr><td class="name">Star</td></tr>
  HTML
      end
       it "should add ordering classes to column" do
        rp = test_report(:order => :name) do
          scope { Entry }
          column(:name)
        end
        subject.datagrid_rows(rp, [entry]).should equal_to_dom(<<-HTML)
  <tr><td class="name ordered asc">Star</td></tr>
  HTML
       end
       it "should add ordering classes to column" do
        rp = test_report(:order => :name, :descending => true) do
          scope { Entry }
          column(:name)
        end
        subject.datagrid_rows(rp, [entry]).should equal_to_dom(<<-HTML)
  <tr><td class="name ordered desc">Star</td></tr>
  HTML
       end

       it "should render html columns" do

        rp = test_report do
          scope { Entry }
          column(:name, :html => true) do |model|
            content_tag(:span, model.name)
          end
        end
        subject.datagrid_rows(rp, [entry]).should equal_to_dom(<<-HTML)
  <tr><td class="name"><span>Star</span></td></tr>
  HTML
       end
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
