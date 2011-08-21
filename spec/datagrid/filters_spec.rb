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
    ModelWithoutTable.should_not be_table_exists
    class TheReport
      include Datagrid

      scope {ModelWithoutTable}

      filter(:name)
    end
    TheReport.new(:name => 'hello')
  end

  describe "allow_blank and allow_nil options" do

    def check_performed(value, result, options)
      $FILTER_PERFORMED = false
      report = test_report(:name => value) do
        scope {Entry}
        filter(:name, options) do |value|
          $FILTER_PERFORMED = true
          self
        end
      end
      report.name.should == value
      report.assets
      $FILTER_PERFORMED.should == result
    end

    it "should support allow_blank argument" do
      [nil, "", " "].each do |value|
        check_performed(value, true, :allow_blank => true)
      end
    end

    it "should support allow_nil argument" do
      check_performed(nil, true, :allow_nil => true)
    end

    it "should support combination on allow_nil and allow_blank" do
      check_performed(nil, false, :allow_nil => false, :allow_blank => true)
      check_performed("", true, :allow_nil => false, :allow_blank => true)
      check_performed(nil, true, :allow_nil => true, :allow_blank => false)
    end
  end
end
