require 'spec_helper'

describe Datagrid::Columns do

  let(:group) { Group.create!(:name => "Pop") }

  subject do
    SimpleReport.new
  end

  describe "basic methods" do

    let!(:entry) {  Entry.create!(
      :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
    ) }
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

  it "should support columns with model and report arguments" do
    report = test_report(:category => "foo") do
      scope {Entry.order(:category)}
      filter(:category) do |value|
        where("category LIKE '%#{value}%'")
      end

      column(:exact_category) do |entry, report|
        entry.category == report.category
      end
    end
    Entry.create!(:category => "foo")
    Entry.create!(:category => "foobar")
    report.rows.first.first.should be_true
    report.rows.last.first.should be_false
  end


end
