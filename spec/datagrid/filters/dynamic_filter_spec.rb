require "spec_helper" 


describe Datagrid::Filters::DynamicFilter do
  let(:report) do
    test_report do
      scope  {Entry}
      filter(:condition, :dynamic)
    end
  end

  it "should support = operation" do
    report.condition = [:name, "=", "hello"]
    report.assets.should include(Entry.create!(:name => 'hello'))
    report.assets.should_not include(Entry.create!(:name => 'bye'))
  end
  it "should support >= operation" do
    report.condition = [:name, ">=", "d"]
    report.assets.should include(Entry.create!(:name => 'x'))
    report.assets.should include(Entry.create!(:name => 'd'))
    report.assets.should_not include(Entry.create!(:name => 'a'))
  end
  it "should blank value" do
    report.condition = [:name, "=", ""]
    report.assets.should include(Entry.create!(:name => 'hello'))
  end
  it "should support =~ operation" do
    report.condition = [:name, "=~", "ell"]
    report.assets.should include(Entry.create!(:name => 'hello'))
    report.assets.should_not include(Entry.create!(:name => 'bye'))
  end
  it "should support >= operation" do
    report.condition = [:group_id, ">=", 2]
    report.assets.should include(Entry.create!(:group_id => 3))
    report.assets.should_not include(Entry.create!(:group_id => 1))
  end
  it "should support <= operation" do
    report.condition = [:group_id, "<=", 2]
    report.assets.should include(Entry.create!(:group_id => 1))
    report.assets.should_not include(Entry.create!(:group_id => 3))
  end
  it "should support <= operation" do
    report.condition = [:group_id, "<=", '2']
    report.assets.should include(Entry.create!(:group_id => 1))
    report.assets.should include(Entry.create!(:group_id => 2))
    report.assets.should_not include(Entry.create!(:group_id => 3))
  end

  it "should support operations for invalid date" do
    report.condition = [:shipping_date, "<=", '1986-08-05']
    report.assets.should include(Entry.create!(:shipping_date => '1986-08-04'))
    report.assets.should include(Entry.create!(:shipping_date => '1986-08-05'))
    report.assets.should_not include(Entry.create!(:shipping_date => '1986-08-06'))
  end

end
