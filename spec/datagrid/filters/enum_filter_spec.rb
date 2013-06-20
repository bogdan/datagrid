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


  it "should support select given as symbol" do
    report = test_report do 
      scope {Entry}
      filter(:group_id, :enum, :select => :selectable_group_ids)
      def selectable_group_ids
        [1,3,5]
      end
    end

    report.filter_by_name(:group_id).select(report).should == [1,3,5]
  end

end
