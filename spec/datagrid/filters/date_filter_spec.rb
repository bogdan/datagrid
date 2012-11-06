require 'spec_helper'

describe Datagrid::Filters::DateFilter do

  it "should support date range argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => 5.day.ago..3.days.ago) do
      scope { Entry } 
      filter(:created_at, :date)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should support date range given as array argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [5.day.ago.to_date.to_s, 3.days.ago.to_date.to_s]) do
      scope { Entry } 
      filter(:created_at, :date, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should support minimum date argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [5.day.ago.to_date.to_s, nil]) do
      scope { Entry } 
      filter(:created_at, :date, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should include(e3)
  end

  it "should support maximum date argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [nil, 3.days.ago.to_date.to_s]) do
      scope { Entry } 
      filter(:created_at, :date, :range => true)
    end
    report.assets.should include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end

  it "should find something in one day interval" do

    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => (4.days.ago.to_date..4.days.ago.to_date)) do
      scope { Entry } 
      filter(:created_at, :date, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should include(e2)
    report.assets.should_not include(e3)
  end
  it "should support invalid range" do

    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => (1.days.ago.to_date..7.days.ago.to_date)) do
      scope { Entry } 
      filter(:created_at, :date, :range => true)
    end
    report.assets.should_not include(e1)
    report.assets.should_not include(e2)
    report.assets.should_not include(e3)
  end


  it "should support block" do
    report = test_report(:created_at => Date.today) do
      scope { Entry } 
      filter(:created_at, :date, :range => true) do |value|
        where("created_at >= ?", value)
      end
    end
    report.assets.should_not include(Entry.create!(:created_at => 1.day.ago))
    report.assets.should include(Entry.create!(:created_at => DateTime.now))
  end
  
end
