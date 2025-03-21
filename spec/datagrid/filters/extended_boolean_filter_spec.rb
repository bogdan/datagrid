# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::ExtendedBooleanFilter do
  it "supports select option" do
    grid = test_grid_filter(:disabled, :xboolean)
    expect(grid.filter_by_name(:disabled).select(grid)).to eq([%w[Yes YES], %w[No NO]])
  end

  it "generates pass boolean value to filter block" do
    grid = test_grid_filter(:disabled, :xboolean)

    disabled_entry = Entry.create!(disabled: true)
    enabled_entry = Entry.create!(disabled: false)

    expect(grid.disabled).to be_nil
    expect(grid.assets).to include(disabled_entry, enabled_entry)
    grid.disabled = "YES"

    expect(grid.disabled).to eq("YES")
    expect(grid.assets).to include(disabled_entry)
    expect(grid.assets).not_to include(enabled_entry)
    grid.disabled = "NO"
    expect(grid.disabled).to eq("NO")
    expect(grid.assets).to include(enabled_entry)
    expect(grid.assets).not_to include(disabled_entry)
  end

  it "normalizes true/false as YES/NO" do
    grid = test_grid_filter(:disabled, :xboolean)

    grid.disabled = true
    expect(grid.disabled).to eq("YES")
    grid.disabled = false
    expect(grid.disabled).to eq("NO")
    grid.disabled = "true"
    expect(grid.disabled).to eq("YES")
    grid.disabled = "false"
    expect(grid.disabled).to eq("NO")
  end
end
