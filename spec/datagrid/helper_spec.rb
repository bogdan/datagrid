require 'spec_helper'
require "will_paginate"
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

describe Datagrid::Helper do
  subject {ActionView::Base.new}

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
<table class="datagrid">
<tr>
<th>Group<div class="order"></div>
</th>
<th>Name<div class="order"></div>
</th>
</tr>

<tr>
<td>Pop</td>
<td>Star</td>
</tr>
</table>
HTML
    end

    it "should support cycle option" do
      subject.datagrid_rows(grid, [entry], :cycle => ["odd", "even"]).should equal_to_dom(<<-HTML)
<tr class="odd">
<td>Pop</td>
<td>Star</td>
</tr>
HTML
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
