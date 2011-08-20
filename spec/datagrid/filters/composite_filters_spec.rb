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
end
