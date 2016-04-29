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
      grid = test_report do
        scope {Entry}
        column(:name)
        column(:action, :html => true) do
          'dummy'
        end
      end
      expect(grid.data_columns.map(&:name)).to eq([:name])
      expect(grid.html_columns.map(&:name)).to eq([:name, :action])
    end
    it "should build rows of data" do
      grid = test_report do
        scope {Entry}
        column(:name)
        column(:action, :html => true) do
          'dummy'
        end
      end
      expect(grid.rows).to eq([["Star"]])
    end
    it  "should generate header without html columns" do
      grid = test_report do
        scope {Entry}
        column(:name)
        column(:action, :html => true) do
          'dummy'
        end
      end
      expect(grid.header).to eq(["Name"])
    end

    describe "translations" do

      module ::Ns45
        class TranslatedReport
          include Datagrid
          scope { Entry }
          column(:name)
        end
      end
      it "translates column with deprecated namespace" do
        silence_warnings do
          store_translations(:en, datagrid: {ns45_translated_report: {columns: {name: "Navn"}}}) do
            expect(Ns45::TranslatedReport.new.header.first).to eq("Navn")
          end
        end
      end

      it "translates column with namespace" do
        store_translations(:en, datagrid: {:"ns45/translated_report" => {columns: {name: "Navn"}}}) do
          expect(Ns45::TranslatedReport.new.header.first).to eq("Navn")
        end
      end

      it "translates column without namespace" do
        class Report27
          include Datagrid
          scope {Entry}
          column(:name)
        end
        store_translations(:en, datagrid: {:"report27" => {columns: {name: "Nombre"}}}) do
          expect(Report27.new.header.first).to eq("Nombre")
        end
      end
    end

    it "should return html_columns" do
      report = test_report do
        scope {Entry}
        column(:id)
        column(:name, :html => false)
      end
      expect(report.html_columns.map(&:name)).to eq([:id])
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
      expect(report.row_for(entry)).to eq([entry.id, "'Hello World' filtered by 'Hello'"])
    end

    it "should generate table data" do
      expect(subject.data).to eq([
        subject.header,
        subject.row_for(entry)
      ])
    end

    it "supports dynamic header" do
      grid = test_report do
        scope {Entry}
        column(:id, header: proc { rand(10**9) })
      end

      expect(grid.header).to_not eq(grid.header)
    end

    it "should generate hash for given asset" do
      expect(subject.hash_for(entry)).to eq({
        :group => "Pop",
        :name => "Star",
        :access_level => 'admin',
        :pet => 'ROTTWEILER',
        :shipping_date => date
      })
    end

    it "should support csv export" do
      expect(subject.to_csv).to eq("Shipping date,Group,Name,Access level,Pet\n#{date},Pop,Star,admin,ROTTWEILER\n")
    end

    it "should support csv export of particular columns" do
      expect(subject.to_csv(:name)).to eq("Name\nStar\n")
    end

    it "should support csv export options" do
      expect(subject.to_csv(:col_sep => ";")).to eq("Shipping date;Group;Name;Access level;Pet\n#{date};Pop;Star;admin;ROTTWEILER\n")
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
    expect(report.rows.first.first).to eq(true)
    expect(report.rows.last.first).to eq(false)
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
    expect(parent.column_by_name(:name)).not_to be_nil
    expect(parent.column_by_name(:group_id)).to be_nil
    expect(child.column_by_name(:name)).not_to be_nil
    expect(child.column_by_name(:group_id)).not_to be_nil
  end
  it "should support defining a query for a column" do
    report = test_report do
      scope {Entry}
      filter(:name)
      column(:id)
      column(:sum_group_id, 'sum(group_id)')
    end
    Entry.create!(:group => group)
    expect(report.assets.first.sum_group_id).to eq(group.id)
  end

    it "should support post formatting for column defined with query" do
      report = test_report do
        scope {Group.joins(:entries).group("groups.id")}
        filter(:name)
        column(:entries_count, 'count(entries.id)') do |model|
          format("(#{model.entries_count})") do |value|
            content_tag(:span, value)
          end
        end
      end
      3.times { Entry.create!(group: group) }
      expect(report.rows).to eq([["(3)"]])
    end
    it "should support hidding columns through if and unless" do
      report = test_report do
        scope {Entry}
        column(:id, :if => :show?)
        column(:name, :unless => proc {|grid| !grid.show? })
        column(:category)

        def show?
          false
        end
      end
      expect(report.columns(:id)).to eq([])
      expect(report.columns(:name)).to eq([])
      expect(report.available_columns.map(&:name)).to eq([:category])
    end

    it "raises when :before and :after used together" do
      expect do
        test_report do
          column(:id)
          column(:name, :before => :id, :after => :name)
        end
      end.to raise_error(Datagrid::ConfigurationError)
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
      expect(grid.header).to eq(["Id", "Name"])
    end
    it "should be suppored in rows" do
      expect(grid.rows).to eq([[entry.id, "hello"]])
    end

    it "should be suppored in csv" do
      expect(grid.to_csv).to eq("Id,Name\n#{entry.id},hello\n")
    end

    it "should support explicit overwrite" do
      expect(grid.header(:id, :name, :category)).to eq(%w(Id Name Category))
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
      expect(report.rows).to eq([["Hello World"]])
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
      expect do
        report.attributes = {:order => :id}
        report.assets
      end.to raise_error(Datagrid::OrderUnsupported)
      report.attributes = {:order => :name, :descending => true}
      expect(report.assets).to eq([second, first])
    end
  end

  describe "fetching data in batches" do
    it "should pass the batch size to the find_each method" do
      report = test_report do
        scope { Entry }
        column :id
        self.batch_size = 25
      end

      fake_assets = double(:assets)
      expect(report).to receive(:assets) { fake_assets }
      expect(fake_assets).to receive(:find_each).with(batch_size: 25)
      expect(fake_assets).to receive(:limit_value).and_return(nil)
      report.rows
    end
    it "should be able to disable batches" do
      report = test_report do
        scope { Entry }
        column :id
        self.batch_size = 0
      end

      fake_assets = double(:assets)

      expect(report).to receive(:assets) { fake_assets }
      expect(fake_assets).to receive(:each)
      expect(fake_assets).not_to receive(:find_each)
      report.rows
    end

    it "should support instance level batch size" do
      grid = test_report do
        scope {Entry}
        column :id
        self.batch_size = 25
      end
      grid.batch_size = 0
      fake_assets = double(:assets)

      expect(grid).to receive(:assets) { fake_assets }
      expect(fake_assets).to receive(:each)
      expect(fake_assets).not_to receive(:find_each)
      grid.rows
    end
  end

  describe ".data_row" do
    it "should give access to column values via an object" do
      grid = test_report do
        scope  { Entry }
        column(:id)
        column(:name) do
          name.capitalize
        end
        column(:actions, html: true) do
          "some link here"
        end
      end
      entry = Entry.create!(name: 'hello')
      row = grid.data_row(entry)
      expect(row.id).to eq(entry.id)
      expect(row.name).to eq("Hello")
      expect {
        row.actions
      }.to raise_error(RuntimeError)
    end
  end

  describe "column value" do
    it "should support conversion" do
      group = Group.create!
      Entry.create(:group => group)
      Entry.create(:group => group)
      grid = test_report do
        scope { Group }
        column(:entries_count) do |g|
          g.entries.count
        end
        column(:odd_entries) do |_, _, row|
          row.entries_count.odd?
        end
      end

      expect(grid.row_for(group)).to eq([2, false])
    end
  end

  describe "instance level column definition" do
    let(:modified_grid) do
      grid = test_report do
        scope { Entry }
        column(:id)
      end
      grid.column(:name)
      grid
    end

    let(:basic_grid) { modified_grid.class.new }
    let!(:entry) { Entry.create!(:name => "Hello", :category => 'first') }

    it "should have correct columns" do
      expect(modified_grid.columns.size).to eq(2)
      expect(basic_grid.class.columns.size).to eq(1)
      expect(basic_grid.columns.size).to eq(1)
    end

    it "should give correct header" do
      expect(modified_grid.header).to eq(["Id", "Name"])
      expect(basic_grid.header).to eq(["Id"])
    end

    it "should give correct rows" do
      expect(modified_grid.rows).to eq([[entry.id, 'Hello']])
      expect(basic_grid.rows).to eq([[entry.id]])
    end

    it "should support :before column name" do
      modified_grid.column(:category, :before => :name)
      expect(modified_grid.header).to eq(["Id", "Category", "Name"])
    end

    it "should support :before all" do
      modified_grid.column(:category, :before => true)
      expect(modified_grid.header).to eq(["Category", "Id", "Name"])
    end

    it "should support columns block" do
      modified_grid.column(:category) do
        category.capitalize
      end
      expect(modified_grid.rows).to eq([[entry.id, "Hello", 'First']])
    end

    it "should support column_names accessor" do
      modified_grid.column_names = [:name]
      expect(modified_grid.rows).to eq([['Hello']])
      modified_grid.column_names = [:id]
      expect(modified_grid.rows).to eq([[entry.id]])
    end
    it "should support column_names accessor with mandatory columns" do
      modified_grid.column(:category, :mandatory => true)
      modified_grid.column_names = [:name]
      expect(modified_grid.rows).to eq([['Hello', 'first']])
      basic_grid.column_names = [:id]
      expect(basic_grid.rows).to eq([[entry.id]])
    end

    it "should support available columns" do
      modified_grid.column(:category, :mandatory => true)
      expect(modified_grid.available_columns.map(&:name)).to eq([:id, :name, :category])
    end

    it "should respect column availability criteria" do
      modified_grid.column(:category, :if => proc { false })
      expect(modified_grid.columns.map(&:name)).to eq([:id, :name])
    end
  end

  describe 'dynamic helper' do
    it "should work" do
      grid = test_report do
        scope {Entry}
        column(:id)
        dynamic {
          column(:name)
          column(:category)
        }
      end

      expect(grid.columns.map(&:name)).to eq([:id, :name, :category])
      expect(grid.class.columns.map(&:name)).to eq([:id])

      expect(grid.column_by_name(:id)).not_to be_nil
      expect(grid.column_by_name(:name)).not_to be_nil
    end

    it "has access to attributes" do
      grid = test_report(:attribute_name => 'value') do
        scope {Entry}
        datagrid_attribute :attribute_name
        dynamic {
          value = attribute_name
          column(:name) { value }
        }
      end

      expect(grid.data_value(:name, Entry.create!)).to eq('value')
    end
  end

  describe ".data_value" do
    it "should return value" do
      grid = test_report do
        scope {Entry }
        column(:name)
      end
      expect(grid.data_value(:name, Entry.create!(:name => 'Hello'))).to eq('Hello')
    end
    it "should raise for disabled columns" do
      grid = test_report do
        scope {Entry }
        column(:name, :if => proc { false })
      end
      expect  {
        grid.data_value(:name, Entry.create!(:name => 'Hello'))
      }.to raise_error(Datagrid::ColumnUnavailableError)
    end
  end

  describe "caching" do
    it "should work when enabled in class" do
      grid = test_report do
        scope {Entry}
        self.cached = true
        column(:random1) {rand(10**9)}
        column(:random2) {rand(10**9)}
      end

      row = grid.data_row(Entry.create!)
      expect(row.random1).to eq(row.random1)
      expect(row.random2).to_not eq(row.random1)
      grid.cached = false
      expect(row.random2).to_not eq(row.random2)
      expect(row.random2).to_not eq(row.random1)
    end
  end

  describe "decoration" do
    class EntryDecorator
      attr_reader :model
      def initialize(model)
        @model = model
      end
      def capitalized_name
        model.name.capitalize
      end
    end

    let!(:entry) do
      Entry.create!(name: 'hello', category: 'first')
    end

    it "delegates column values to decorator" do
      grid = test_report do
        scope { Entry }
        decorate { |model| EntryDecorator.new(model) }
        column(:capitalized_name)
        column(:category) do |presenter|
          presenter.model.category
        end
        column(:capitalized_name_dup) do |_, _, row|
          row.capitalized_name
        end
      end

      expect(grid.rows).to eq([['Hello', 'first', 'Hello']])
    end

    it "allows class decorator" do
      grid = test_report do
        scope { Entry }
        decorate { EntryDecorator }
        column(:capitalized_name)
      end
      expect(grid.rows).to eq([['Hello']])
    end
  end
end
