require "spec_helper" 


describe Datagrid::Filters::StringFilter do

  it "should support multiple values" do
    report = test_report(:name => "one,two") do
      scope {Entry}
      filter(:name, :string, :multiple => true)
    end
    expect(report.assets).to include(Entry.create!( :name => "one"))
    expect(report.assets).to include(Entry.create!( :name => "two"))
    expect(report.assets).not_to include(Entry.create!( :name => "three"))
  end
  it "should support custom separator multiple values" do
    report = test_report(:name => "one,1|two,2") do
      scope {Entry}
      filter(:name, :string, :multiple => '|')
    end
    expect(report.assets).to include(Entry.create!( :name => "one,1"))
    expect(report.assets).to include(Entry.create!( :name => "two,2"))
    expect(report.assets).not_to include(Entry.create!( :name => "one"))
    expect(report.assets).not_to include(Entry.create!( :name => "two"))
  end

end
