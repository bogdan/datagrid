require 'spec_helper'

describe Datagrid::Columns do

  let(:group) { Group.create!(:name => "Pop") }

  subject do
    SimpleReport.new
  end

  describe "basic methods" do

    let!(:entry) {  Entry.create!(
      :group => group,
      :name => "Star",
      :disabled => false,
      :confirmed => false,
      :category => "first",
      :access_level => 'admin',
      :pet => 'rottweiler',
      :shipping_date => Date.new(2013, 8, 1)
    ) }
    let(:date) { Date.new(2013, 8, 1) }

    it "should have data columns without html columns" do
      subject.data_columns.size.should == subject.columns.size - 1
    end
    it "should build rows of data" do
      subject.rows.should == [[date, "Pop", "Star", "admin", "ROTTWEILER"]]
    end
    it  "should generate header" do
      subject.header.should == ["Shipping date", "Group", "Name", "Access level", "Pet"]
    end
    
    it "should return html_columns" do
      report = test_report do
        scope {Entry}
        column(:id)
        column(:name, :html => false)
      end
      report.html_columns.map(&:name).should == [:id]
    end

    it "should return html_columns when column definition has 2 arguments" do
      report = test_report(:name => "Hello") do
        scope {Entry}
        filter(:name)
        column(:id)
        column(:name, :html => false) do |model, grid|
          "'#{model.name}' filtered by '#{grid.name}'"
        end
      end
      report.row_for(Entry.create!(:name => "Hello World")).should == [8, "'Hello World' filtered by 'Hello'"]
    end

    it "should generate table data" do
      subject.data.should == [
        subject.header,
        subject.row_for(entry)
      ]
    end

    it "should generate hash for given asset" do
      subject.hash_for(entry).should == {
        :group => "Pop",
        :name => "Star",
        :access_level => 'admin',
        :pet => 'ROTTWEILER',
        :shipping_date => date
      }
    end

    it "should support csv export" do
      subject.to_csv.should == "Shipping date,Group,Name,Access level,Pet\n#{date},Pop,Star,admin,ROTTWEILER\n"
    end

    it "should support csv export of particular columns" do
      subject.to_csv(:name).should == "Name\nStar\n"
    end

    it "should support csv export options" do
      subject.to_csv(:col_sep => ";").should == "Shipping date;Group;Name;Access level;Pet\n#{date};Pop;Star;admin;ROTTWEILER\n"
    end
  end

  it "should support columns with model and report arguments" do
    report = test_report(:category => "foo") do
      scope {Entry.order(:category)}
      filter(:category) do |value|
        where("category LIKE '%#{value}%'")
      end

      column(:exact_category) do |entry, grid|
        entry.category == grid.category
      end
    end
    Entry.create!(:category => "foo")
    Entry.create!(:category => "foobar")
    report.rows.first.first.should be_true
    report.rows.last.first.should be_false
  end

  it "should inherit columns correctly" do
    parent = Class.new do
      include Datagrid
      scope { Entry }
      column(:name)
    end

    child = Class.new(parent) do
      column(:group_id)
    end
    parent.column_by_name(:name).should_not be_nil
    parent.column_by_name(:group_id).should be_nil
    child.column_by_name(:name).should_not be_nil
    child.column_by_name(:group_id).should_not be_nil
  end

  describe ".column_names attributes" do
    let(:grid) do
      test_report(:column_names => ["id", "name"]) do
        scope { Entry }
        column(:id)
        column(:name)
        column(:category)
      end
    end
    let!(:entry) do
      Entry.create!(:name => 'hello')
    end
    it "should be suppored in header" do
      grid.header.should == ["Id", "Name"]
    end
    it "should be suppored in rows" do
      grid.rows.should == [[entry.id, "hello"]]
    end

    it "should be suppored in csv" do
      grid.to_csv.should == "Id,Name\n#{entry.id},hello\n"
    end

    it "should support explicit overwrite" do
      grid.header(:id, :name, :category).should == %w(Id Name Category)
    end

  end


  context "when grid has formatted column" do
    it "should output correct data" do
      report = test_report do
        scope {Entry}
        column(:name) do |entry|
          format(entry.name) do |value|
            "<strong>#{value}</strong"
          end
        end
      end
      Entry.create!(:name => "Hello World")
      report.rows.should == [["Hello World"]]
    end
  end
end
