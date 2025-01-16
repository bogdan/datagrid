# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters do
  it "supports default option as proc" do
    expect(
      test_grid_filter(
        :created_at, :date, default: proc { Date.today },
      ).created_at,
    ).to eq(Date.today)
  end

  it "stacks with other filters" do
    Entry.create(name: "ZZ", category: "first")
    report = test_grid(name: "Pop", category: "first") do
      scope  { Entry }
      filter(:name)
      filter(:category, :enum, select: %w[first second])
    end
    expect(report.assets).to be_empty
  end

  it "does not support array argument for not multiple filter" do
    report = test_grid_filter(:group_id, :integer)
    expect do
      report.group_id = [1, 2]
    end.to raise_error(Datagrid::ArgumentError)
  end

  it "filters block with 2 arguments" do
    report = test_grid_filter(:group_id, :integer) do |value, scope|
      scope.where(group_id: value)
    end
    expect do
      report.group_id = [1, 2]
    end.to raise_error(Datagrid::ArgumentError)
  end

  it "initializes when report Scope table not exists" do
    class ModelWithoutTable < ActiveRecord::Base; end
    expect(ModelWithoutTable).not_to be_table_exists
    class TheReport < Datagrid::Base
      scope { ModelWithoutTable }

      filter(:name)
      filter(:limit)
    end
    expect(TheReport.new(name: "hello")).not_to be_nil
  end

  it "supports inheritence" do
    parent = Class.new(Datagrid::Base) do
      scope { Entry }
      filter(:name)
    end
    child = Class.new(parent) do
      filter(:group_id)
    end
    expect(parent.filters.size).to eq(1)
    expect(child.filters.size).to eq(2)
  end

  describe "allow_blank and allow_nil options" do
    def check_performed(value, result, **options)
      filter_performed = false
      report = test_grid_filter(:name, **options) do |_|
        filter_performed = true
        self
      end
      report.name = value
      expect(report.name).to eq(value)
      report.assets
      expect(filter_performed).to eq(result)
    end

    it "supports allow_blank argument" do
      [nil, "", " "].each do |value|
        check_performed(value, true, allow_blank: true)
      end
    end

    it "supports allow_nil argument" do
      check_performed(nil, true, allow_nil: true)
    end

    it "supports combination on allow_nil and allow_blank" do
      check_performed(nil, false, allow_nil: false, allow_blank: true)
      check_performed("", true, allow_nil: false, allow_blank: true)
      check_performed(nil, true, allow_nil: true, allow_blank: false)
    end
  end

  describe "default filter as scope" do
    it "creates default filter if scope respond to filter name method" do
      Entry.create!
      Entry.create!
      grid = test_grid_filter(:limit)
      grid.limit = 1
      expect(grid.assets.to_a.size).to eq(1)
    end
  end

  describe "default filter as scope" do
    it "creates default filter if scope respond to filter name method" do
      Entry.create!
      grid = test_grid_filter(:custom) do |value|
        where(custom: value) if value != "skip"
      end
      grid.custom = "skip"
      expect(grid.assets).not_to be_empty
    end
  end

  describe "positioning filter before another" do
    it "inserts the filter before the specified element" do
      grid = test_grid do
        scope { Entry }
        filter(:limit)
        filter(:name, before: :limit)
      end
      expect(grid.filters.index { |f| f.name == :name }).to eq(0)
    end
  end

  describe "positioning filter after another" do
    it "inserts the filter before the specified element" do
      grid = test_grid do
        scope { Entry }
        filter(:limit)
        filter(:name)
        filter(:group_id, after: :limit)
      end
      expect(grid.filters.index { |f| f.name == :group_id }).to eq(1)
    end
  end

  it "supports dummy filter" do
    grid = test_grid_filter(:period, :date, dummy: true, default: proc { Date.today })
    Entry.create!(created_at: 3.days.ago)
    expect(grid.assets).not_to be_empty
  end

  describe "#filter_by" do
    it "allows partial filtering" do
      grid = test_grid do
        scope { Entry }
        filter(:id)
        filter(:name)
      end
      Entry.create!(name: "hello")
      grid.attributes = { id: -1, name: "hello" }
      expect(grid.assets).to be_empty
      expect(grid.filter_by(:name)).not_to be_empty
    end
  end

  it "supports dynamic header" do
    grid = test_grid_filter(:id, :integer, header: proc { rand(10**9) })

    filter = grid.filter_by_name(:id)
    expect(filter.header).not_to eq(filter.header)
  end

  describe "#filter_by_name" do
    it "returns filter object" do
      r = test_grid_filter(:id, :integer)

      object = r.filter_by_name(:id)
      expect(object.type).to eq(:integer)
    end
  end

  describe "tranlations" do
    module ::Ns46
      class TranslatedReport < Datagrid::Base
        scope { Entry }
        filter(:name)
      end

      class InheritedReport < TranslatedReport
      end
    end

    it "translates filter with namespace" do
      grid = Ns46::TranslatedReport.new
      store_translations(:en, datagrid: { "ns46/translated_report": { filters: { name: "Navn" } } }) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end

    it "translates filter using defaults namespace" do
      grid = Ns46::TranslatedReport.new
      store_translations(:en, datagrid: { defaults: { filters: { name: "Navn" } } }) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end

    it "translates filter using parent report" do
      grid = Ns46::InheritedReport.new
      store_translations(:en, datagrid: { "ns46/translated_report": { filters: { name: "Navn" } } }) do
        expect(grid.filters.map(&:header)).to eq(["Navn"])
      end
    end

    it "translates filter using configured general namespace" do
      grid = test_grid do
        self.i18n_configuration = { namespace: "other.location" }

        scope { Entry }
        filter(:name)
      end

      store_translations(:en, other: { location: { name: "Nosaukums" } }) do
        expect(grid.filters.map(&:header)).to eq(["Nosaukums"])
      end
    end

    it "prefers filters-specific translation namespace if configured" do
      grid = test_grid do
        self.i18n_configuration = { namespace: "other.general", filters_namespace: "other.filters" }

        scope { Entry }
        filter(:name)
      end

      store_translations(:en, other: { general: { name: "Nosaukums" }, filters: { name: "Nosaukuma filtrs" } }) do
        expect(grid.filters.map(&:header)).to eq(["Nosaukuma filtrs"])
      end
    end
  end

  describe "#select_options" do
    it "returns select options" do
      filters = {
        id: [1, 2],
        name: [["a", 1], ["b", 2]],
        category: { a: 1, b: 2 },
      }
      grid = test_grid do
        scope { Entry }
        filters.each do |name, options|
          filter(name, :enum, select: options, multiple: true)
        end
      end
      filters.each do |name, options|
        expect(grid.select_options(name)).to eq(options)
        expect(grid.select_values(name)).to eq([1, 2])
        grid.select_all(name)
        expect(grid.public_send(name)).to eq([1, 2])
      end
    end

    it "raises ArgumentError for filter without options" do
      grid = test_grid_filter(:id, :integer)
      expect do
        grid.select_options(:id)
      end.to raise_error(Datagrid::ArgumentError)
    end
  end

  describe "#inspect" do
    it "lists all fitlers with types" do
      module ::NsInspect
        class TestGrid < Datagrid::Base
          scope { Entry }
          filter(:id, :integer)
          filter(:name, :string)
          filter(:current_user)
        end
      end

      expect(NsInspect::TestGrid.inspect).to eq(
        "NsInspect::TestGrid(id: integer, name: string, current_user: default)",
      )
    end

    it "dislays no filters" do
      class TestGrid8728 < Datagrid::Base
        scope { Entry }
      end

      expect(TestGrid8728.inspect).to eq("TestGrid8728(no filters)")
    end
  end

  describe ":if :unless options" do
    it "supports :if option" do
      klass = test_grid_class do
        scope { Entry }
        filter(:admin_mode, :boolean, dummy: true)
        filter(:id, :integer, if: :admin_mode)
        filter(:name, :integer, unless: :admin_mode)
      end

      admin_filters = klass.new(admin_mode: true).filters.map(&:name)
      non_admin_filters = klass.new(admin_mode: false).filters.map(&:name)
      expect(admin_filters).to include(:id)
      expect(admin_filters).not_to include(:name)
      expect(non_admin_filters).not_to include(:id)
      expect(non_admin_filters).to include(:name)
    end

    context "with delegation to attribute" do
      subject { klass.new(role: role).filters.map(&:name) }

      let(:role) { Struct.new(:admin).new(admin) }
      let(:klass) do
        test_grid_class do
          attr_accessor :role

          delegate :admin, to: :role

          scope { Entry }

          filter(:id, :integer, if: :admin)
        end
      end

      context "when condition is true" do
        let(:admin) { true }

        it { is_expected.to include(:id) }
      end

      context "when condition is false" do
        let(:admin) { false }

        it { is_expected.not_to include(:id) }
      end
    end
  end
end
