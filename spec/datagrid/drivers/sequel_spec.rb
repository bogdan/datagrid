# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Drivers::Sequel do
  describe ".match?" do
    subject { described_class }

    it { is_expected.to be_match(SequelEntry) }
    it { is_expected.to be_match(SequelEntry.where(id: 1)) }
    it { is_expected.not_to be_match(Entry.where(id: 1)) }
  end

  describe "api" do
    subject do
      SequelGrid.new(
        defined?(_attributes) ? _attributes : {},
      )
    end

    let!(:first) do
      SequelEntry.create(
        group_id: 2,
        name: "Main First",
        disabled: false,
      )
    end
    let!(:second) do
      SequelEntry.create(
        group_id: 3,
        name: "Main Second",
        disabled: true,
      )
    end

    it "supports pagination" do
      class PaginationTest < Datagrid::Base
        scope { SequelEntry }
      end
      grid = PaginationTest.new do |scope|
        scope.paginate(1, 25)
      end
      expect(grid.rows.to_a).to be_a(Array)
      expect(grid.assets.to_a).to be_a(Array)
    end

    describe "#assets" do
      subject { super().assets }

      it { is_expected.to include(first, second) }
    end

    describe "#assets" do
      subject { super().assets }

      describe "#size" do
        subject { super().count }

        it { is_expected.to eq(2) }
      end
    end

    describe "#rows" do
      subject { super().rows }

      it { is_expected.to eq([["Main First", 2, false], ["Main Second", 3, true]]) }
    end

    describe "#header" do
      subject { super().header }

      it { is_expected.to eq(%w[Name Group Disabled]) }
    end

    describe "#data" do
      subject { super().data }

      it { is_expected.to eq([["Name", "Group", "Disabled"], ["Main First", 2, false], ["Main Second", 3, true]]) }
    end

    describe "when some filters specified" do
      let(:_attributes) { { group_id: 3..100 } }

      describe "#assets" do
        subject { super().assets.map(&:id) }

        it { is_expected.not_to include(first.id) }
      end

      describe "#assets" do
        subject { super().assets }

        it { is_expected.to include(second) }
      end
    end

    describe "when reverse ordering is specified" do
      let(:_attributes) { { order: :name, descending: true } }

      describe "#rows" do
        subject { super().rows }

        it { is_expected.to eq([["Main Second", 3, true], ["Main First", 2, false]]) }
      end
    end

    it "provides default order for non declared fields" do
      expect do
        test_grid(order: :test) do
          scope { SequelEntry }
          column(:test) do
            "test"
          end
        end.assets
      end.to raise_error(Datagrid::OrderUnsupported)
    end

    it "supports batch_size" do
      report = test_grid do
        scope { SequelEntry }
        self.batch_size = 1
        column(:name)
      end

      expect(report.data).to eq([["Name"], ["Main First"], ["Main Second"]])
    end
  end
end
