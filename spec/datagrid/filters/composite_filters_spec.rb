require 'spec_helper'

describe Datagrid::Filters::CompositeFilters do
  
  describe ".date_range_filters" do
    
    it "should generate from date and to date filters" do
      e1 = Entry.create!(:shipping_date => 6.days.ago)
      e2 = Entry.create!(:shipping_date => 4.days.ago)
      e3 = Entry.create!(:shipping_date => 1.days.ago)
      assets = test_report(:from_shipping_date => 5.days.ago, :to_shipping_date => 2.day.ago) do
        scope {Entry}
        date_range_filters(:shipping_date)
      end.assets

      assets.should include(e2)
      assets.should_not include(e1, e3)
    end
  end
  
  describe ".integer_range_filters" do
    
    it "should generate from integer and to integer filters" do
      e1 = Entry.create!(:group_id => 1)
      e2 = Entry.create!(:group_id => 3)
      e3 = Entry.create!(:group_id => 5)
      assets = test_report(:from_group_id => 2, :to_group_id => 4) do
        scope {Entry}
        integer_range_filters(:group_id)
      end.assets

      assets.should include(e2)
      assets.should_not include(e1, e3)
    end
  end
end
