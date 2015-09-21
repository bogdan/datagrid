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
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  {:active_record => Entry, :mongoid => MongoidEntry, :sequel => SequelEntry}.each do |orm, klass|
    describe "with orm #{orm}", orm => true do
      describe "date to timestamp conversion" do
        let(:klass) { klass }
        subject do
          test_report(:created_at => _created_at) do
            scope { klass }
            filter(:created_at, :date, :range => true)
          end.assets.to_a
        end

        def entry_dated(date)
          klass.create(:created_at => date)
        end

        context "when single date paramter given" do
          let(:_created_at) { Date.today }
          it { should include(entry_dated(1.second.ago))}
          it { should include(entry_dated(Date.today.end_of_day))}
          it { should_not include(entry_dated(Date.today.beginning_of_day - 1.second))}
          it { should_not include(entry_dated(Date.today.end_of_day + 1.second))}
        end

        context "when range date range given" do
          let(:_created_at) { [Date.yesterday, Date.today] }
          it { should include(entry_dated(1.second.ago))}
          it { should include(entry_dated(1.day.ago))}
          it { should include(entry_dated(Date.today.end_of_day))}
          it { should include(entry_dated(Date.yesterday.beginning_of_day))}
          it { should_not include(entry_dated(Date.yesterday.beginning_of_day - 1.second))}
          it { should_not include(entry_dated(Date.today.end_of_day + 1.second))}
        end
      end

    end
  end

  it "should support date range given as array argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [5.day.ago.to_date.to_s, 3.days.ago.to_date.to_s]) do
      scope { Entry }
      filter(:created_at, :date, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "should support minimum date argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [5.day.ago.to_date.to_s, nil]) do
      scope { Entry }
      filter(:created_at, :date, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).to include(e3)
  end

  it "should support maximum date argument" do
    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => [nil, 3.days.ago.to_date.to_s]) do
      scope { Entry }
      filter(:created_at, :date, :range => true)
    end
    expect(report.assets).to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "should find something in one day interval" do

    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => (4.days.ago.to_date..4.days.ago.to_date)) do
      scope { Entry }
      filter(:created_at, :date, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end
  it "should support invalid range" do

    e1 = Entry.create!(:created_at => 7.days.ago)
    e2 = Entry.create!(:created_at => 4.days.ago)
    e3 = Entry.create!(:created_at => 1.day.ago)
    report = test_report(:created_at => (1.days.ago.to_date..7.days.ago.to_date)) do
      scope { Entry }
      filter(:created_at, :date, :range => true)
    end
    expect(report.assets).not_to include(e1)
    expect(report.assets).not_to include(e2)
    expect(report.assets).not_to include(e3)
  end


  it "should support block" do
    report = test_report(:created_at => Date.today) do
      scope { Entry }
      filter(:created_at, :date, :range => true) do |value|
        where("created_at >= ?", value)
      end
    end
    expect(report.assets).not_to include(Entry.create!(:created_at => 1.day.ago))
    expect(report.assets).to include(Entry.create!(:created_at => Time.now))
  end


  context "when date format is configured" do
    around(:each) do |example|
      with_date_format do
        example.run
      end
    end

    it "should have configurable date format" do
      report = test_report(:created_at => "10/01/2013") do
        scope  {Entry}
        filter(:created_at, :date)
      end
      expect(report.created_at).to eq(Date.new(2013,10,01))
    end

    it "should support default explicit date" do
      report = test_report(:created_at => Date.parse("2013-10-01")) do
        scope  {Entry}
        filter(:created_at, :date)
      end
      expect(report.created_at).to eq(Date.new(2013,10,01))
    end
  end


  it "should automatically reverse Array if first more than last" do
    report = test_report(:created_at => ["2013-01-01", "2012-01-01"]) do
      scope  {Entry}
      filter(:created_at, :date, :range => true)
    end
    expect(report.created_at).to eq([Date.new(2012, 01, 01), Date.new(2013, 01, 01)])
  end
  it "should automatically reverse Array if first more than last" do
    report = test_report(:created_at => ["2013-01-01", "2012-01-01"]) do
      scope  {Entry}
      filter(:created_at, :date, :range => true)
    end
    expect(report.created_at).to eq([Date.new(2012, 01, 01), Date.new(2013, 01, 01)])
  end

  it "should properly format date in filter_value_as_string" do
    with_date_format do
      report = test_report(:created_at => "2012-01-02") do
        scope  {Entry}
        filter(:created_at, :date)
      end
      expect(report.filter_value_as_string(:created_at)).to eq("01/02/2012")
    end
  end

end
