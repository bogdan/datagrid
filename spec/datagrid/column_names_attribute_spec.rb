require "spec_helper"

describe Datagrid::ColumnNamesAttribute do

  subject do
    test_report do
      scope { Entry }
      column_names_filter()
      column(:id)
      column(:name, :mandatory => true)
      column(:category)
    end
  end

  let!(:entry) do
    Entry.create!(:name => 'hello', :category => 'greeting')
  end

  describe ".column_names_filter" do
    it "should work" do
      subject.column_names = [:id]
      subject.mandatory_columns.map(&:name).should == [:name]
      subject.optional_columns.map(&:name).should == [:id, :category]
      subject.data.should == [["Id", "Name"], [entry.id, "hello"]]
      columns_filter = subject.filter_by_name(:column_names)
      columns_filter.should_not be_nil
      columns_filter.select(subject).should == [["Id", :id], ["Category", :category]]
    end
  end

  context "with mandatory columns" do
    it "should show only mandatory columns by default" do
      subject.row_for(entry).should == [ "hello" ]
      subject.column_names = ["name", "category"]
      subject.row_for(entry).should == ["hello", "greeting"]
    end
  end
end
