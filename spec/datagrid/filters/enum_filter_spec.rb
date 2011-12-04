require 'spec_helper'

describe Datagrid::Filters::EnumFilter do

  it "should support select option" do
    test_report do
      scope {Entry}
      filter(:group_id, :enum, :select =>  [1,2] )
    end.class.filter_by_name(:group_id).select.should == [1,2]
  end

  it "should support select option as proc" do
    test_report do
      scope {Entry}
      filter(:group_id, :enum, :select => proc { [1,2] })
    end.class.filter_by_name(:group_id).select.should == [1,2]
  end
  
  it "should stack with other filters" do
    Entry.create(:name => "ZZ", :category => "first")
    report = test_report(:name => "Pop", :category => "first") do
      scope  { Entry }
      filter(:name)
      filter(:category, :enum, :select => ["first", "second"])
    end
    report.assets.should be_empty
  end
end
