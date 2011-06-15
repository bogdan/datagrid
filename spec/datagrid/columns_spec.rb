require 'spec_helper'

describe Datagrid::Columns do
  
  let(:group) { Group.create!(:name => "Pop") }
  let!(:entry) {  Entry.create!(
    :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
  ) }
  
  subject do
    SimpleReport.new
  end
  it "should build rows of data" do
    subject.rows.should == [["Pop", "Star"]]
  end
  it  "should generate header" do
    subject.header.should == ["Group", "Name"]
  end

  it "should generate data" do
    subject.data.should == [
      subject.header,
      subject.row_for(entry)
    ]
  end

  it "should support csv export" do
    subject.to_csv.should == "Group,Name\nPop,Star\n"
  end
end
