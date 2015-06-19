require 'spec_helper'

describe Datagrid::Filters::DateTimeFilter do
  {:active_record => Entry, :mongoid => MongoidEntry}.each do |orm, klass|
    describe "with orm #{orm}", orm => true do
      describe "timestamp to timestamp conversion" do
        let(:klass) { klass }

        let(:grid) do
          test_report(:created_at => _created_at) do
            scope { klass }
            filter(:created_at, :datetime, :range => true)
          end
        end

        subject do
          grid.assets.to_a
        end

        def entry_dated(date)
          klass.create(:created_at => date)
        end

        context "when single datetime paramter given" do
          let(:_created_at) { Time.now.change(sec: 0) }
          it { should include(entry_dated(_created_at)) }
          it { should_not include(entry_dated(_created_at - 1.second))}
          it { should_not include(entry_dated(_created_at + 1.second))}
        end

        context "when range datetime range given" do
          let(:_created_at) { [Time.now.beginning_of_day, Time.now.end_of_day] }
          it { should include(entry_dated(1.second.ago))}
          it { should include(entry_dated(Date.today.to_time))}
          it { should include(entry_dated(Time.now.end_of_day.to_time))}
          it { should_not include(entry_dated(Date.yesterday.end_of_day))}
          it { should_not include(entry_dated(Date.tomorrow.beginning_of_day))}
        end
      end

    end
  end

  it "should support datetime range given as array argument" do
    e1 = Entry.create!(:created_at => Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(:created_at => Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(:created_at => Time.new(2013, 1, 1, 3, 0))
    report = test_report(:created_at => [Time.new(2013, 1, 1, 1, 30).to_s, Time.new(2013, 1, 1, 2, 30).to_s]) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "should support minimum datetime argument" do
    e1 = Entry.create!(:created_at => Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(:created_at => Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(:created_at => Time.new(2013, 1, 1, 3, 0))
    report = test_report(:created_at => [Time.new(2013, 1, 1, 1, 30).to_s, nil]) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).to include(e3)
  end

  it "should support maximum datetime argument" do
    e1 = Entry.create!(:created_at => Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(:created_at => Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(:created_at => Time.new(2013, 1, 1, 3, 0))
    report = test_report(:created_at => [nil, Time.new(2013, 1, 1, 2, 30).to_s]) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.assets).to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "should find something in one second interval" do

    e1 = Entry.create!(:created_at => Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(:created_at => Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(:created_at => Time.new(2013, 1, 1, 3, 0))
    report = test_report(:created_at => (Time.new(2013, 1, 1, 2, 0)..Time.new(2013, 1, 1, 2, 0))) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end
  it "should support invalid range" do

    e1 = Entry.create!(:created_at => Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(:created_at => Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(:created_at => Time.new(2013, 1, 1, 3, 0))
    report = test_report(:created_at => (Time.new(2013, 1, 1, 3, 0)..Time.new(2013, 1, 1, 1, 0))) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).not_to include(e2)
    expect(report.assets).not_to include(e3)
  end


  it "should support block" do
    report = test_report(:created_at => Time.now) do
      scope { Entry }
      filter(:created_at, :datetime, :range => true) do |value|
        where("created_at >= ?", value)
      end
    end
    expect(report.assets).not_to include(Entry.create!(:created_at => 1.day.ago))
    expect(report.assets).to include(Entry.create!(:created_at => Time.now+1.day))
  end


  context "when datetime format is configured" do
    around(:each) do |example|
      with_datetime_format("%m/%d/%Y %H:%M") do
        example.run
      end
    end

    it "should have configurable datetime format" do
      report = test_report(:created_at => "10/01/2013 01:00") do
        scope  {Entry}
        filter(:created_at, :datetime)
      end
      expect(report.created_at).to eq(Time.new(2013,10,01,1,0))
    end

    it "should support default explicit datetime" do
      report = test_report(:created_at => Time.parse("2013-10-01 01:00")) do
        scope  {Entry}
        filter(:created_at, :datetime)
      end
      expect(report.created_at).to eq(Time.new(2013,10,01,1,0))
    end
  end


  it "should automatically reverse Array if first more than last" do
    report = test_report(:created_at => ["2013-01-01 01:00", "2012-01-01 01:00"]) do
      scope  {Entry}
      filter(:created_at, :datetime, :range => true)
    end
    expect(report.created_at).to eq([Time.new(2012, 01, 01, 1, 0), Time.new(2013, 01, 01, 1, 0)])
  end
end
