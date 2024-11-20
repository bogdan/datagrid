# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Drivers::Mongoid, :mongoid do
  describe ".match?" do
    subject { described_class }

    it { is_expected.to be_match(MongoidEntry) }
    it { is_expected.to be_match(MongoidEntry.scoped) }
    it { is_expected.not_to be_match(Entry.where(id: 1)) }
  end

  describe "api" do
    subject do
      MongoidGrid.new(
        defined?(_attributes) ? _attributes : {},
      )
    end

    let!(:first) do
      MongoidEntry.create!(
        group_id: 2,
        name: "Main First",
        disabled: false,
      )
    end
    let!(:second) do
      MongoidEntry.create!(
        group_id: 3,
        name: "Main Second",
        disabled: true,
      )
    end

    describe "#assets" do
      subject { super().assets }

      it { is_expected.to include(first, second) }
    end

    describe "#assets" do
      subject { super().assets }

      describe "#size" do
        subject { super().size }

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
      let(:_attributes) { { group_id: [3, nil] } }

      describe "#assets" do
        subject { super().assets.map(&:_id) }

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

    it "does not provide default order for non declared fields" do
      expect do
        test_grid(order: :test) do
          scope { MongoidEntry }
          column(:test)
        end.assets
      end.to raise_error(Datagrid::OrderUnsupported)
    end

    it "supports batch_size" do
      report = test_grid do
        scope { MongoidEntry }
        self.batch_size = 1
        column(:name)
      end

      expect(report.data).to eq([["Name"], ["Main First"], ["Main Second"]])
    end
  end
end
