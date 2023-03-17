require "spec_helper"

describe Datagrid::Filters::TextFilter do
  it "should support single values" do
    report = test_report(:name => "one,two") do
      scope { Entry }
      filter(:name, :text)
    end
    expect(report.assets).to include(Entry.create!( :name => "one,two"))
  end
end
