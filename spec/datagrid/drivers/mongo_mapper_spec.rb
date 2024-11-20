# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Drivers::MongoMapper, :mongomapper do
  if defined?(MongoMapper)
    describe ".match?" do
      subject { described_class }

      it { is_expected.to match(MongoMapperEntry) }
      # MongoMapper doesn't have a scoped method, instead it has a query method which returns a Plucky::Query object
      it { is_expected.to match(MongoMapperEntry.query) }
      it { is_expected.not_to match(Entry.where(id: 1)) }
    end

    describe "api" do
      subject do
        MongoMapperGrid.new(
          defined?(_attributes) ? _attributes : {},
        )
      end

      let!(:first) do
        MongoMapperEntry.create!(
          group_id: 2,
          name: "Main First",
          disabled: false,
        )
      end
      let!(:second) do
        MongoMapperEntry.create!(
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

          it { is_expected.to == 2 }
        end
      end

      describe "#rows" do
        subject { super().rows }

        it { is_expected.to == [["Main First", 2, false], ["Main Second", 3, true]] }
      end

      describe "#header" do
        subject { super().header }

        it { is_expected.to == %w[Name Group Disabled] }
      end

      describe "#data" do
        subject { super().data }

        it { is_expected.to == [["Name", "Group", "Disabled"], ["Main First", 2, false], ["Main Second", 3, true]] }
      end

      describe "when some filters specified" do
        let(:_attributes) { { group_id: [3, nil] } }

        describe "#assets" do
          subject { super().assets }

          it { is_expected.not_to include(first) }
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

          it { is_expected.to == [["Main Second", 3, true], ["Main First", 2, false]] }
        end
      end

      it "does not provide default order for non declared fields" do
        expect do
          test_grid(order: :test) do
            scope { MongoMapperEntry }
            column(:test)
          end.assets
        end.to raise_error(Datagrid::OrderUnsupported)
      end
    end
  end
end
