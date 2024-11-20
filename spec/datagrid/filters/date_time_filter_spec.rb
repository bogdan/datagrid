# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::DateTimeFilter do
  { active_record: Entry, mongoid: MongoidEntry }.each do |orm, klass|
    describe "with orm #{orm}", orm => true do
      describe "timestamp to timestamp conversion" do
        subject do
          grid.assets.to_a
        end

        let(:klass) { klass }

        let(:grid) do
          test_grid(created_at: _created_at) do
            scope { klass }
            filter(:created_at, :datetime, range: true)
          end
        end

        def entry_dated(date)
          klass.create!(created_at: date)
        end

        def include_entry(date)
          entry = entry_dated(date)
          expect(subject).to include(entry)
        end

        def not_include_entry(date)
          entry = entry_dated(date)
          expect(subject).not_to include(entry)
        end

        context "with single datetime parameter given" do
          let(:_created_at) { Time.now.change(sec: 0) }

          it { include_entry(_created_at) }
          it { not_include_entry(_created_at - 1.second) }
          it { not_include_entry(_created_at + 1.second) }
        end

        context "with range datetime range given" do
          let(:_created_at) { [Time.now.beginning_of_day, Time.now.end_of_day] }

          it { include_entry(1.second.ago) }
          it { include_entry(Date.today.to_time) }
          it { include_entry(Time.now.end_of_day.to_time) }
          it { not_include_entry(Date.yesterday.end_of_day) }
          it { not_include_entry(Date.tomorrow.beginning_of_day) }
        end

        context "with right open range" do
          let(:_created_at) { Time.now.beginning_of_day..nil }

          it { include_entry(1.second.ago) }
          it { include_entry(Date.today.to_time) }
          it { include_entry(Time.now.end_of_day.to_time) }
          it { include_entry(Date.tomorrow.beginning_of_day) }
          it { not_include_entry(Date.yesterday.end_of_day) }
        end

        context "with left open range" do
          let(:_created_at) { nil..Time.now.end_of_day }

          it { include_entry(1.second.ago) }
          it { include_entry(Date.today.to_time) }
          it { include_entry(Time.now.end_of_day.to_time) }
          it { include_entry(Date.yesterday.end_of_day) }
          it { not_include_entry(Date.tomorrow.beginning_of_day) }
        end
      end
    end
  end

  it "supports datetime range given as array argument" do
    e1 = Entry.create!(created_at: Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(created_at: Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(created_at: Time.new(2013, 1, 1, 3, 0))

    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = [Time.new(2013, 1, 1, 1, 30).to_s, Time.new(2013, 1, 1, 2, 30).to_s]

    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "supports minimum datetime argument" do
    e1 = Entry.create!(created_at: Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(created_at: Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(created_at: Time.new(2013, 1, 1, 3, 0))

    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = [Time.new(2013, 1, 1, 1, 30).to_s, nil]

    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).to include(e3)
  end

  it "supports maximum datetime argument" do
    e1 = Entry.create!(created_at: Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(created_at: Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(created_at: Time.new(2013, 1, 1, 3, 0))

    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = [nil, Time.new(2013, 1, 1, 2, 30).to_s]

    expect(report.assets).to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "finds something in one second interval" do
    e1 = Entry.create!(created_at: Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(created_at: Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(created_at: Time.new(2013, 1, 1, 3, 0))

    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = Time.new(2013, 1, 1, 2, 0)..Time.new(2013, 1, 1, 2, 0)

    expect(report.assets).not_to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).not_to include(e3)
  end

  it "reverses invalid range" do
    range = Time.new(2013, 1, 1, 3, 0)..Time.new(2013, 1, 1, 1, 0)
    e1 = Entry.create!(created_at: Time.new(2013, 1, 1, 1, 0))
    e2 = Entry.create!(created_at: Time.new(2013, 1, 1, 2, 0))
    e3 = Entry.create!(created_at: Time.new(2013, 1, 1, 3, 0))

    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = range

    expect(report.created_at).to eq(range.last..range.first)
    expect(report.assets).to include(e1)
    expect(report.assets).to include(e2)
    expect(report.assets).to include(e3)
  end

  it "supports block" do
    report = test_grid_filter(:created_at, :datetime) do |value|
      where("created_at >= ?", value)
    end
    report.created_at = Time.now

    expect(report.assets).not_to include(Entry.create!(created_at: 1.day.ago))
    expect(report.assets).to include(Entry.create!(created_at: Time.now + 1.day))
  end

  context "when datetime format is configured" do
    around do |example|
      with_datetime_format("%m/%d/%Y %H:%M") do
        example.run
      end
    end

    it "has configurable datetime format" do
      report = test_grid_filter(:created_at, :datetime)
      report.created_at = "10/01/2013 01:00"
      expect(report.created_at).to eq(Time.new(2013, 10, 0o1, 1, 0))
    end

    it "supports default explicit datetime" do
      report = test_grid_filter(:created_at, :datetime)
      report.created_at = Time.parse("2013-10-01 01:00")

      expect(report.created_at).to eq(Time.new(2013, 10, 0o1, 1, 0))
    end
  end

  it "automaticallies reverse Array if first more than last" do
    report = test_grid_filter(:created_at, :datetime, range: true)
    report.created_at = ["2013-01-01 01:00", "2012-01-01 01:00"]

    expect(report.created_at).to eq(Time.new(2012, 0o1, 0o1, 1, 0)..Time.new(2013, 0o1, 0o1, 1, 0))
  end

  it "supports serialized range value" do
    from = Time.parse("2013-01-01 01:00")
    to = Time.parse("2013-01-02 02:00")
    report = test_grid_filter(:created_at, :datetime, range: true)

    report.created_at = (from..to).as_json
    expect(report.created_at).to eq(from..to)

    report.created_at = (from..).as_json
    expect(report.created_at).to eq(from..)

    report.created_at = (..to).as_json
    expect(report.created_at).to eq(..to)

    report.created_at = (from...to).as_json
    expect(report.created_at).to eq(from...to)

    report.created_at = (nil..nil).as_json
    expect(report.created_at).to be_nil

    report.created_at = (nil...nil).as_json
    expect(report.created_at).to be_nil
  end
end
