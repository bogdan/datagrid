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

      expect(assets).to include(e2)
      expect(assets).not_to include(e1, e3)
    end

    it "should support options" do
      report = test_report do
        report = date_range_filters(:shipping_date, {:default => 10.days.ago.to_date}, {:default => Date.today})
      end
      expect(report.from_shipping_date).to eq(10.days.ago.to_date)
      expect(report.to_shipping_date).to eq(Date.today)
    end
    it "should support table name in field" do
      report = test_report do
        report = date_range_filters("entries.shipping_date", {:default => 10.days.ago.to_date}, {:default => Date.today})
      end
      expect(report.from_entries_shipping_date).to eq(10.days.ago.to_date)
      expect(report.to_entries_shipping_date).to eq(Date.today)
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

      expect(assets).to include(e2)
      expect(assets).not_to include(e1, e3)
    end
    it "should support options" do
      report = test_report do
        report = integer_range_filters(:group_id, {:default => 0}, {:default => 100})
      end
      expect(report.from_group_id).to eq(0)
      expect(report.to_group_id).to eq(100)
    end
    it "should table name in field name" do
      report = test_report do
        report = integer_range_filters("entries.group_id", {:default => 0}, {:default => 100})
      end
      expect(report.from_entries_group_id).to eq(0)
      expect(report.to_entries_group_id).to eq(100)
    end
  end
end
