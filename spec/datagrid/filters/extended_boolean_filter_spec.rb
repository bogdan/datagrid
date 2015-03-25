require 'spec_helper'

describe Datagrid::Filters::ExtendedBooleanFilter do

  it "should support select option" do
    grid = test_report do
      scope {Entry}
      filter(:disabled, :xboolean)
    end
    expect(grid.filter_by_name(:disabled).select(grid)).to eq([["Yes", "YES"], ["No", "NO"]])
  end

  it "should generate pass boolean value to filter block" do
    grid = test_report do
      scope {Entry}
      filter(:disabled, :xboolean)
    end

    disabled_entry = Entry.create!(:disabled => true)
    enabled_entry = Entry.create!(:disabled => false)

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

  it "should normalize true/false as YES/NO" do
    grid = test_report do
      scope {Entry}
      filter(:disabled, :xboolean)
    end
    grid.disabled = true
    expect(grid.disabled).to eq("YES")
    grid.disabled = false
    expect(grid.disabled).to eq("NO")
  end

end
