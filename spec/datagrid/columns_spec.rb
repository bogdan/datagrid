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
      entry = Entry.create!(:name => "Hello World")
      report.row_for(entry).should == [entry.id, "'Hello World' filtered by 'Hello'"]
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

    it "should apply decorator" do
      row_value = Struct.new(:group, :name, :access_level, :pet, :shipping_date)
      subject.decorator_value = proc do |r|
        row_value.new(
          double(:group, :name => r.group.name[0]),
          r.name[0],
          r.access_level[0],
          r.pet[0],
          r.shipping_date.year
        )
      end
      expect(subject.hash_for(entry)).to eq(
        :group => "P",
        :name => "S",
        :access_level => "a",
        :pet => "R",
        :shipping_date => 2013
      )
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

  describe "#row_for" do
    it "should apply decorator" do
      row_value = Struct.new(:id, :greeting)
      report = test_report do
        scope { Entry }
        decorator { |r| row_value.new(r.id, "Hello, #{r.name}") }
        column(:id)
        column(:greeting)
      end
      entry = Entry.create!(:name => "World")
      report.row_for(entry).should == [entry.id, "Hello, World"]
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

  describe ".default_column_options" do
    it "should pass default options to each column definition" do
      report = test_report do
        scope {Entry}
        self.default_column_options = {:order => false}
        column(:id)
        column(:name, :order => "name")
      end
      first = Entry.create(:name => '1st')
      second = Entry.create(:name => '2nd')
      proc { report.attributes = {:order => :id} }.should raise_error(Datagrid::OrderUnsupported)
      report.attributes = {:order => :name, :descending => true}
      report.assets.should == [second, first]
    end
  end

  describe "decorator" do
    it "sets a row value mapping block on the class" do
      row_value = Struct.new(:original_asset)
      report_class = test_report_class do
        decorator { |r| row_value.new(r) }
      end
      decorated_asset = report_class.decorator_value.call(:example)
      expect(decorated_asset).to eq row_value.new(:example)
    end

    it "is settable on the instance" do
      row_value = Struct.new(:original_asset)
      report = test_report
      report.decorator { |r| row_value.new(r) }
      decorated_asset = report.decorator_value.call(:example)
      expect(decorated_asset).to eq row_value.new(:example)
    end
  end

  context "with a decorated report" do
    let(:row_value) { Struct.new(:original_asset) }

    let(:report) {
      example_decorator = row_value
      test_report do |g|
        g.scope     { ["a", "b"] }
        g.decorator { |r| example_decorator.new(r) }
      end
    }

    describe "decorate" do
      it "applies the report decorator" do
        decorated_asset = report.decorate(:example)
        expect(decorated_asset).to eq row_value.new(:example)
      end
    end

    describe "decorated_assets" do
      it "applies the report decorator to all scoped assets" do
        assets = report.decorated_assets
        expect(assets).to eq [row_value.new("a"), row_value.new("b")]
      end
    end
  end

end
