# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::BaseFilter do
  it "supports default option as block" do
    report = test_grid do
      scope { Entry }
      filter(:name, :string, default: :name_default)
      def name_default
        "hello"
      end
    end
    expect(report.assets).to include(Entry.create!(name: "hello"))
    expect(report.assets).not_to include(Entry.create!(name: "world"))
    expect(report.assets).not_to include(Entry.create!(name: ""))
  end

  describe "#default_scope?" do
    it "identifies filters without custom block" do
      grid = test_grid do
        scope { Entry }
        filter(:id, :integer)
        filter(:group_id, :integer) do |value, _scope|
          scope("group_id >= ?", value)
        end
      end

      expect(grid.filter_by_name(:id)).to be_default_scope
      expect(grid.filter_by_name(:group_id)).not_to be_default_scope
    end
  end

  describe "dummy options" do
    it "causes filter never apply" do
      grid = test_grid_filter(:period, :date, dummy: true, default: proc { Date.today })
      Entry.create!(created_at: 3.days.ago)
      expect(grid.assets).not_to be_empty
    end

    it "conflicts with block" do
      expect do
      test_grid_filter(:period, :date, dummy: true) do |value, scope|
        scope
      end
      end.to raise_error(Datagrid::ConfigurationError)
    end
  end
end
