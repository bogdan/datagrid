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

end
