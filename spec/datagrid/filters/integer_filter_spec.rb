require 'spec_helper'

describe Datagrid::Filters::IntegerFilter do

  it "should support integer range argument" do
    e1 = Entry.create!(:group_id => 1)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 7)
    report = test_report(:group_id => 3..5) do
      scope { Entry } 
      filter(:group_id, :integer)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should support integer range given as array argument" do
    e1 = Entry.create!(:group_id => 7)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 1)
    report = test_report(:group_id => [3.to_s, 5.to_s]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should support minimum integer argument" do
    e1 = Entry.create!(:group_id => 1)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 7)
    report = test_report(:group_id => [5.to_s, nil]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should_not include(e2)
    report.assets.should include(e3)
  end

  it "should support maximum integer argument" do
    e1 = Entry.create!(:group_id => 1)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 7)
    report = test_report(:group_id => [nil, 5.to_s]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    report.assets.should include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should find something in one integer interval" do

    e1 = Entry.create!(:group_id => 7)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 1)
    report = test_report(:group_id => (4..4)) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end
  it "should support invalid range" do

    e1 = Entry.create!(:group_id => 7)
    e2 = Entry.create!(:group_id => 4)
    e3 = Entry.create!(:group_id => 1)
    report = test_report(:group_id => (7..1)) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should_not include(e2)
    report.assets.should_not include(e3)
  end


  it "should support block" do
    report = test_report(:group_id => 5) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true) do |value|
        where("group_id >= ?", value)
      end
    end
    report.assets.should_not include(Entry.create!(:group_id => 1))
    report.assets.should include(Entry.create!(:group_id => 5))
  end


  it "should not prefix table name if column is joined" do
    report = test_report(:rating => [4,nil]) do
      scope { Entry.joins(:group) } 
      filter(:rating, :integer, :range => true)
    end
    report.assets.should_not include(Entry.create!(:group => Group.create!(:rating => 3)))
    report.assets.should include(Entry.create!(:group => Group.create!(:rating => 5)))
  end

  
end
