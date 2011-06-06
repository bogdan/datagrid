require 'spec_helper'
require "will_paginate"
require "active_support/core_ext/hash"
require "active_support/core_ext/object"

describe Datagrid::Helper do
  subject {ActionView::Base.new}

  before(:each) do
    subject.stub!(:params).and_return({})
    subject.stub(:url_for) do |options|
      "http://localhost?" + options.to_param
    end
    
  end

  let(:group) { Group.create!(:name => "Pop") }
  let!(:entry) {  Entry.create!(
    :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
  ) }
  let(:grid) { SimpleReport.new }

  describe ".report_table" do
    it "should return data table html" do
      subject.datagrid_table(grid).should equal_to_dom(<<-HTML)
       <table class="datagrid">
       <tr>
       <th>Group<div class="order">
       <a href="http://localhost?#{{:report => grid.attributes.merge(:order => "groups.name")}.to_param}">ASC</a> 
       <a href="http://localhost?#{{:report => grid.attributes.merge(:order => "groups.name DESC")}.to_param}">DESC</a>
       </div>
       </th>
       <th>Name<div class="order">
       <a href="http://localhost?#{{:report => grid.attributes.merge(:order => "entries.name")}.to_param}">ASC</a> 
       <a href="http://localhost?#{{:report => grid.attributes.merge(:order => "entries.name DESC")}.to_param}">DESC</a>
       </div>
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
