# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::IntegerFilter do
  let(:entry1) { Entry.create!(group_id: 1) }
  let(:entry2) { Entry.create!(group_id: 2) }
  let(:entry3) { Entry.create!(group_id: 3) }
  let(:entry4) { Entry.create!(group_id: 4) }
  let(:entry5) { Entry.create!(group_id: 5) }
  let(:entry7) { Entry.create!(group_id: 7) }

  it "supports integer range argument" do
    report = test_grid_filter(:group_id, :integer, range: true)

    report.group_id = 3..5
    expect(report.assets).not_to include(entry1)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry7)
    report.group_id = (4..)
    expect(report.assets).to include(entry4)
    expect(report.assets).to include(entry5)
    expect(report.assets).not_to include(entry3)
    report.group_id = (..2)
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
    expect(report.assets).not_to include(entry3)
  end

  it "supports integer range given as array argument" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = [3.to_s, 5.to_s]
    expect(report.group_id).to eq(3..5)
  end

  it "supports minimum integer argument" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = [5.to_s, nil]

    expect(report.group_id).to eq(5..)
  end

  it "supports maximum integer argument" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = [nil, 5.to_s]

    expect(report.group_id).to eq(..5)
  end

  it "finds something in one integer interval" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = 4

    expect(report.assets).not_to include(entry7)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry1)
  end

  it "supports range inversion" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = 7..1

    expect(report.group_id).to eq(1..7)
  end

  it "converts infinite range to nil" do
    report = test_grid_filter(:group_id, :integer, range: true)
    report.group_id = nil..nil

    expect(report.group_id).to be_nil
  end

  it "supports block" do
    report = test_grid_filter(:group_id, :integer, range: true) do |value|
      where("group_id >= ?", value)
    end
    report.group_id = 5

    expect(report.assets).not_to include(entry1)
    expect(report.assets).to include(entry5)
  end

  it "does not prefix table name if column is joined" do
    report = test_grid(rating: [4, nil]) do
      scope { Entry.joins(:group) }
      filter(:rating, :integer, range: true)
    end
    expect(report.rating).to eq(4..nil)
    expect(report.assets).not_to include(Entry.create!(group: Group.create!(rating: 3)))
    expect(report.assets).to include(Entry.create!(group: Group.create!(rating: 5)))
  end

  it "supports multiple values" do
    report = test_grid_filter(:group_id, :integer, multiple: true)
    report.group_id = "1,2"

    expect(report.group_id).to eq([1, 2])
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
    expect(report.assets).not_to include(entry3)
  end

  it "supports custom separator multiple values" do
    report = test_grid_filter(:group_id, :integer, multiple: "|")
    report.group_id = "1|2"

    expect(report.group_id).to eq([1, 2])
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
    expect(report.assets).not_to include(entry3)
  end

  it "supports multiple with allow_blank allow_nil options" do
    report = test_grid_filter(:group_id, :integer, multiple: true, allow_nil: false, allow_blank: true)

    report.group_id = []
    expect(report.assets).not_to include(entry1)
    expect(report.assets).not_to include(entry2)
    report.group_id = [1]
    expect(report.assets).to include(entry1)
    expect(report.assets).not_to include(entry2)
    report.group_id = nil
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
  end

  it "normalizes AR object to ID" do
    report = test_grid_filter(:group_id, :integer)
    group = Group.create!
    report.group_id = group

    expect(report.group_id).to eq(group.id)
  end

  it "supports serialized range value" do
    report = test_grid_filter(:group_id, :integer, range: true)

    report.group_id = (1..5).as_json
    expect(report.group_id).to eq(1..5)

    report.group_id = (1..).as_json
    expect(report.group_id).to eq(1..)

    report.group_id = (..5).as_json
    expect(report.group_id).to eq(..5)

    report.group_id = (1...5).as_json
    expect(report.group_id).to eq(1...5)

    report.group_id = (nil..nil).as_json
    expect(report.group_id).to be_nil

    report.group_id = (nil...nil).as_json
    expect(report.group_id).to be_nil
  end

  it "type casts value" do
    report = test_grid_filter(:group_id, :integer)

    report.group_id = "1"
    expect(report.group_id).to eq(1)

    report.group_id = " 1 "
    expect(report.group_id).to eq(1)

    report.group_id = 1.1
    expect(report.group_id).to eq(1)

    report.group_id = "1.1"
    expect(report.group_id).to eq(1)

    report.group_id = "-1"
    expect(report.group_id).to eq(-1)

    report.group_id = "-1.1"
    expect(report.group_id).to eq(-1)

    report.group_id = "1a"
    expect(report.group_id).to eq(1)

    report.group_id = "aa"
    expect(report.group_id).to be_nil

    report.group_id = "a1"
    expect(report.group_id).to be_nil
  end
end
