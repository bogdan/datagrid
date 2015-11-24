require 'spec_helper'

describe Datagrid::Filters::BaseFilter do
  

  it "should support default option as block" do
    report = test_report do
      scope {Entry}
      filter(:name, :string, :default => :name_default)
      def name_default
        'hello'
      end
    end
    expect(report.assets).to include(Entry.create!(:name => "hello"))
    expect(report.assets).not_to include(Entry.create!(:name => "world"))
    expect(report.assets).not_to include(Entry.create!(:name => ""))
  end

end
