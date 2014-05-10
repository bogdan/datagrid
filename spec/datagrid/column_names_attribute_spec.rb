require "spec_helper"

describe Datagrid::ColumnNamesAttribute do

  let(:column_names_filter_options) do
    {}
  end

  let(:report) do
    options = column_names_filter_options
    test_report do
      scope { Entry }
      column_names_filter(options)
      column(:id)
      column(:name, :mandatory => true)
      column(:category)
    end
  end
  subject { report }


  let!(:entry) do
    Entry.create!(:name => 'hello', :category => 'greeting')
  end

  it "should work" do
    subject.column_names = [:id]
    subject.mandatory_columns.map(&:name).should == [:name]
    subject.optional_columns.map(&:name).should == [:id, :category]
    subject.data.should == [["Id", "Name"], [entry.id, "hello"]]
    columns_filter = subject.filter_by_name(:column_names)
    columns_filter.should_not be_nil
    columns_filter.select(subject).should == [["Id", :id], ["Category", :category]]
  end

  it "should show only mandatory columns by default" do
    subject.row_for(entry).should == [ "hello" ]
    subject.column_names = ["name", "category"]
    subject.row_for(entry).should == ["hello", "greeting"]
  end

  it "should find any column by name" do
    subject.column_by_name(:id).should_not be_nil
    subject.column_by_name(:name).should_not be_nil
    subject.column_by_name(:category).should_not be_nil
  end


  context "when default option is passed to column_names_filter" do
    let(:column_names_filter_options) do
      { :default => [:id] }
    end
    its(:data) { should == [["Id", "Name"], [entry.id, 'hello']] }

  end
end
