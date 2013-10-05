require "spec_helper" 


describe Datagrid::Filters::StringFilter do

  it "should support multiple values" do
    report = test_report(:name => "one,two") do
      scope {Entry}
      filter(:name, :string, :multiple => true)
    end
    report.assets.should include(Entry.create!( :name => "one"))
    report.assets.should include(Entry.create!( :name => "two"))
    report.assets.should_not include(Entry.create!( :name => "three"))
  end
  it "should support custom separator multiple values" do
    report = test_report(:name => "one,1|two,2") do
      scope {Entry}
      filter(:name, :string, :multiple => '|')
    end
    report.assets.should include(Entry.create!( :name => "one,1"))
    report.assets.should include(Entry.create!( :name => "two,2"))
    report.assets.should_not include(Entry.create!( :name => "one"))
    report.assets.should_not include(Entry.create!( :name => "two"))
  end

end
