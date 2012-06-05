require 'spec_helper'

describe Datagrid::Core do
  
  it "should support change scope on the fly" do
    report = test_report do
      scope { Entry }
    end
    report.scope do
      Entry.limit(1)
    end
    2.times { Entry.create }
    report.assets.to_a.size.should == 1
  end
end
