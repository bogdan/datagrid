require 'spec_helper'

describe Datagrid::Filters do

  it "should support default option as proc" do
    expect(test_report do
      scope {Entry}
      filter(:created_at, :date, :default => proc { Date.today } )
    end.created_at).to eq(Date.today)
  end

  it "should stack with other filters" do
    Entry.create(:name => "ZZ", :category => "first")
    report = test_report(:name => "Pop", :category => "first") do
      scope  { Entry }
      filter(:name)
      filter(:category, :enum, :select => ["first", "second"])
    end
    expect(report.assets).to be_empty
  end

  it "should not support array argument for not multiple filter" do
    report = test_report do
      scope {Entry}
      filter(:group_id, :integer)
    end
    expect {
      report.group_id = [1,2]
    }.to raise_error(Datagrid::ArgumentError)
  end

  it "should filter block with 2 arguments" do
    report = test_report do
      scope {Entry}
      filter(:group_id, :integer) do |value, scope|
        scope.where(:group_id => value)
      end
    end
    expect {
      report.group_id = [1,2]
    }.to raise_error(Datagrid::ArgumentError)
  end


  it "should initialize when report Scope table not exists" do
    class ModelWithoutTable < ActiveRecord::Base; end
    expect(ModelWithoutTable).not_to be_table_exists
    class TheReport
      include Datagrid

      scope {ModelWithoutTable}

      filter(:name)
      filter(:limit)
    end
    expect(TheReport.new(:name => 'hello')).not_to be_nil
  end

  it "should support inheritence" do
    parent = Class.new do
      include Datagrid
      scope {Entry}
      filter(:name)
    end
    child = Class.new(parent) do
      filter(:group_id)
    end
    expect(parent.filters.size).to eq(1)
    expect(child.filters.size).to eq(2)
  end

  describe "allow_blank and allow_nil options" do

    def check_performed(value, result, options)
      $FILTER_PERFORMED = false
      report = test_report(:name => value) do
        scope {Entry}
        filter(:name, options) do |_|
          $FILTER_PERFORMED = true
          self
        end
      end
      expect(report.name).to eq(value)
      report.assets
      expect($FILTER_PERFORMED).to eq(result)
    end

    it "should support allow_blank argument" do
      [nil, "", " "].each do |value|
        check_performed(value, true, :allow_blank => true)
      end
    end

    it "should support allow_nil argument" do
      check_performed(nil, true, :allow_nil => true)
    end

    it "should support combination on allow_nil and allow_blank" do
      check_performed(nil, false, :allow_nil => false, :allow_blank => true)
      check_performed("", true, :allow_nil => false, :allow_blank => true)
      check_performed(nil, true, :allow_nil => true, :allow_blank => false)
    end
  end

  describe "default filter as scope" do
    it "should create default filter if scope respond to filter name method" do
      Entry.create!
      Entry.create!
      grid = test_report(:limit => 1) do
        scope {Entry}
        filter(:limit)
      end
      expect(grid.assets.to_a.size).to eq(1)
    end

  end
  describe "default filter as scope" do
    it "should create default filter if scope respond to filter name method" do
      Entry.create!
      grid = test_report(:custom => 'skip') do
        scope {Entry}
        filter(:custom) do |value|
          if value != 'skip'
            where(:custom => value)
          end
        end
      end
      expect(grid.assets).not_to be_empty
    end

  end

  describe "positioning filter before another" do
    it "should insert the filter before the specified element" do
      grid = test_report do
        scope {Entry}
        filter(:limit)
        filter(:name, :before => :limit)
      end
      expect(grid.filters.index {|f| f.name == :name}).to eq(0)
    end
  end

  describe "positioning filter after another" do
    it "should insert the filter before the specified element" do
      grid = test_report do
        scope {Entry}
        filter(:limit)
        filter(:name)
        filter(:group_id, :after => :limit)
      end
      expect(grid.filters.index {|f| f.name == :group_id}).to eq(1)
    end
  end

  it "should support dummy filter" do
    grid = test_report do
      scope { Entry }
      filter(:period, :date, :dummy => true, :default => proc { Date.today })
    end
    Entry.create!(:created_at => 3.days.ago)
    expect(grid.assets).not_to be_empty
  end

  describe "#filter_by" do
    it "should allow partial filtering" do
      grid = test_report do
        scope {Entry}
        filter(:id)
        filter(:name)
      end
      Entry.create!(:name => 'hello')
      grid.attributes = {:id => -1, :name => 'hello'}
      expect(grid.assets).to be_empty
      expect(grid.filter_by(:name)).not_to be_empty
    end
  end

  it "supports dynamic header" do
    grid = test_report do
      scope {Entry}
      filter(:id, :integer, header: proc { rand(10**9) })
    end

    filter = grid.filter_by_name(:id)
    expect(filter.header).to_not eq(filter.header)
  end


  describe "#filter_by_name" do
    it "should return filter object" do
      r = test_report do
        scope {Entry}
        filter(:id, :integer)
      end

      object = r.filter_by_name(:id)
      expect(object.type).to eq(:integer)
    end
  end

  describe "tranlations" do

    module ::Ns46
      class TranslatedReport
        include Datagrid
        scope { Entry }
        filter(:name)
      end

      class InheritedReport < TranslatedReport
      end
    end

    it "translates filter with namespace" do
      grid = Ns46::TranslatedReport.new
      store_translations(:en, datagrid: {:"ns46/translated_report" => {filters: {name: "Navn"}}}) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end

    it "translates filter using defaults namespace" do
      grid = Ns46::TranslatedReport.new
      store_translations(:en, datagrid: {defaults: {filters: {name: "Navn"}}}) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end

    it "translates filter using parent report" do
      grid = Ns46::InheritedReport.new
      store_translations(:en, datagrid: {:"ns46/translated_report" => {filters: {name: "Navn"}}}) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end
  end


  describe "#select_options" do
    it "should return select options" do
      grid = test_report do
        scope {Entry}
        filter(:id, :enum, select: [1,2,3])
      end
      expect(grid.select_options(:id)).to eq([1,2,3])
    end

    it "should raise ArgumentError for filter without options" do
      grid = test_report do
        scope {Entry}
        filter(:id, :integer)
      end
      expect {
        grid.select_options(:id)
      }.to raise_error(Datagrid::ArgumentError)
    end
  end

  describe "#inspect" do
    it "should list all fitlers with types" do

      module ::NsInspect
        class TestGrid
          include Datagrid
          scope {Entry}
          filter(:id, :integer)
          filter(:name, :string)
          filter(:current_user)
        end
      end

      expect(NsInspect::TestGrid.inspect).to eq(
        "NsInspect::TestGrid(id: integer, name: string, current_user: default)"
      )
    end

    it "dislays no filters" do
      class TestGrid8728
        include Datagrid
        scope {Entry}
      end

      expect(TestGrid8728.inspect).to eq("TestGrid8728(no filters)")
    end
  end


  describe ":if :unless options" do
    it "supports :if option" do
      klass = test_report_class do
        scope {Entry}
        filter(:admin_mode, :boolean, dummy: true)
        filter(:id, :integer, if: :admin_mode)
        filter(:name, :integer, unless: :admin_mode)
      end

      admin_filters = klass.new(admin_mode: true).filters.map(&:name)
      non_admin_filters = klass.new(admin_mode: false).filters.map(&:name)
      expect(admin_filters).to include(:id)
      expect(admin_filters).to_not include(:name)
      expect(non_admin_filters).to_not include(:id)
      expect(non_admin_filters).to include(:name)
    end

    context 'with delegation to attribute' do
      let(:role) { OpenStruct.new('admin?' => admin) }
      let(:klass) do
        test_report_class do
          attr_accessor :role
          delegate :admin?, to: :role

          scope { Entry }

          filter(:id, :integer, if: :admin?)
        end
      end

      subject { klass.new(role: role).filters.map(&:name) }

      context 'when condition is true' do
        let(:admin) { true }

        it { is_expected.to include(:id) }
      end

      context 'when condition is false' do
        let(:admin) { false }

        it { is_expected.to_not include(:id) }
      end
    end
  end
end
