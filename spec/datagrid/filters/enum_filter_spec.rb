require 'spec_helper'

describe Datagrid::Filters::EnumFilter do

  it "should support select option" do
    report = test_report do
      scope {Entry}
      filter(:group_id, :enum, :select =>  [1,2] )
    end
    expect(report.filter_by_name(:group_id).select(report)).to eq([1,2])
  end

  it "should support select option as proc" do
    grid = test_report do
      scope {Entry}
      filter(:group_id, :enum, :select => proc { [1,2] })
    end
    expect(grid.filter_by_name(:group_id).select(grid)).to eq([1,2])
  end

  it "should support select option as proc with instace input" do
    klass = test_report do
              scope {Entry}
              filter(:group_id, :enum, :select => proc { |obj| obj.object_id })
            end.class
    instance = klass.new
    expect(klass.filter_by_name(:group_id).select(instance)).to eq(instance.object_id)
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

    expect(report.filter_by_name(:group_id).select(report)).to eq([1,3,5])
  end

end
