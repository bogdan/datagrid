require 'spec_helper'

describe Datagrid::Filters::ExtendedBooleanFilter do

  it "should support select option" do
    test_report do
      scope {Entry}
      filter(:disabled, :xboolean)
    end.class.filter_by_name(:disabled).select.should == [["Yes", "YES"], ["No", "NO"]]
  end

  it "should generate pass boolean value to filter block" do
    grid = test_report do
      scope {Entry}
      filter(:disabled, :xboolean)
    end

    disabled_entry = Entry.create!(:disabled => true)
    enabled_entry = Entry.create!(:disabled => false)

    grid.disabled.should be_nil
    grid.assets.should include(disabled_entry, enabled_entry)
    grid.disabled = "YES"

    grid.disabled.should == "YES"
    grid.assets.should include(disabled_entry)
    grid.assets.should_not include(enabled_entry)
    grid.disabled = "NO"
    grid.disabled.should == "NO"
    grid.assets.should include(enabled_entry)
    grid.assets.should_not include(disabled_entry)

  end

end
