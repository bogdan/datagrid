require 'spec_helper'

describe Datagrid::Filters::EnumFilter do

  it "should support select option" do
    test_report do
      scope {Entry}
      filter(:group_id, :enum, :select =>  [1,2] )
    end.class.filter_by_name(:group_id).select.should == [1,2]
  end

  it "should support select option as proc" do
    test_report do
      scope {Entry}
      filter(:group_id, :enum, :select => proc { [1,2] })
    end.class.filter_by_name(:group_id).select.should == [1,2]
  end

  it "should support select option as proc with instace input" do
    klass = test_report do
              scope {Entry}
              filter(:group_id, :enum, :select => proc { |obj| obj.object_id })
            end.class
    instance = klass.new
    klass.filter_by_name(:group_id).select(instance).should == instance.object_id
  end
  
  it "should initialize select option only on instanciation" do
    class ReportWithLazySelect
      include Datagrid
      scope {Entry}
      filter(:group_id, :enum, :select => proc { raise 'hello' })
    end
  end

end
