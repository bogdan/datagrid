# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::StringFilter do
  it "should support multiple values" do
    report = test_grid_filter(:name, :string, multiple: true)
    report.name = "one,two"

    expect(report.assets).to include(Entry.create!(name: "one"))
    expect(report.assets).to include(Entry.create!(name: "two"))
    expect(report.assets).not_to include(Entry.create!(name: "three"))
  end
  it "should support custom separator multiple values" do
    report = test_grid_filter(:name, :string, multiple: "|")
    report.name = "one,1|two,2"

    expect(report.assets).to include(Entry.create!(name: "one,1"))
    expect(report.assets).to include(Entry.create!(name: "two,2"))
    expect(report.assets).not_to include(Entry.create!(name: "one"))
    expect(report.assets).not_to include(Entry.create!(name: "two"))
  end

  it "supports range" do
    report = test_grid_filter(:name, :string, range: true)
    report.name = %w[ab lm]

    expect(report.assets).to include(Entry.create!(name: "ac"))
    expect(report.assets).to include(Entry.create!(name: "kl"))
    expect(report.assets).not_to include(Entry.create!(name: "aa"))
    expect(report.assets).not_to include(Entry.create!(name: "mn"))
  end
end
