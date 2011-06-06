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

  describe ".report_table" do
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
       <tr class="odd">
       <td>Pop</td>
       <td>Star</td>
       </tr>
       </table>
       HTML
    end
  end
  

end
