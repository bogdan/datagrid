# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::BooleanFilter do
  it "applies default filtering" do
    grid = test_grid do
      scope { Entry }
      filter(:disabled, :boolean)
    end

    disabled_entry = Entry.create!(disabled: true)
    enabled_entry = Entry.create!(disabled: false)

    expect(grid.disabled).to be(false)
    expect(grid.assets).to include(disabled_entry, enabled_entry)
    grid.disabled = true

    expect(grid.disabled).to eq(true)
    expect(grid.assets).to include(disabled_entry)
    expect(grid.assets).not_to include(enabled_entry)
    grid.disabled = false
    expect(grid.disabled).to eq(false)
    expect(grid.assets).to include(enabled_entry)
    expect(grid.assets).to include(disabled_entry)
  end

  it "type casts any value to boolean" do
    grid = test_grid do
      scope { Entry }
      filter(:disabled, :boolean)
    end

    grid.disabled = true
    expect(grid.disabled).to eq(true)

    grid.disabled = false
    expect(grid.disabled).to eq(false)

    grid.disabled = 1
    expect(grid.disabled).to eq(true)

    grid.disabled = 0
    expect(grid.disabled).to eq(false)

    grid.disabled = "true"
    expect(grid.disabled).to eq(true)

    grid.disabled = "false"
    expect(grid.disabled).to eq(false)
  end
end
