require 'spec_helper'

describe Datagrid::Filters do

  it "should support default option as proc" do
    test_report do
      scope {Entry}
      filter(:created_at, :date, :default => proc { Date.today } )
    end.created_at.should == Date.today
  end
  
end
