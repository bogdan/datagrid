require 'spec_helper'

describe Datagrid::Filters do

  it "should support default option as proc" do
    test_report do
      scope {Entry}
      filter(:created_at, :date, :default => proc { Date.today } )
    end.created_at.should == Date.today
  end

  it "should not support array argument for not multiple filter" do
    report = test_report do
      scope {Entry}
      filter(:group_id, :integer)
    end
    lambda {
      report.group_id = [1,2]
    }.should raise_error(Datagrid::ArgumentError)
  end
  

  it "should initialize report Scope table not exists" do
    class ModelWithoutTable < ActiveRecord::Base; end
    class TheReport
      include Datagrid

      scope {ModelWithoutTable}

      filter(:name)
    end

  end
  
end
