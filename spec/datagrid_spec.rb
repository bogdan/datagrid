# frozen_string_literal: true

require "spec_helper"
require "datagrid/rspec"

describe Datagrid do
  subject do
    SimpleReport.new(
      group_id: group.id,
      name: "Star",
      category: "first",
      disabled: false,
      confirmed: false,
    )
  end

  let!(:entry) do
    Entry.create!(
      group: group, name: "Star", disabled: false, confirmed: false, category: "first",
    )
  end
  let(:group) { Group.create!(name: "Pop") }

  describe SimpleReport do
    it_behaves_like "Datagrid"
  end

  describe "#assets" do
    subject { super().assets }

    it { is_expected.to include(entry) }
  end

  describe ".attributes" do
    it "returns report attributes" do
      (subject.filters.map(&:name) + %i[order descending]).each do |attribute|
        expect(subject.attributes).to have_key(attribute)
      end
    end
  end

  describe ".scope" do
    it "returns defined scope of objects" do
      expect(subject.scope).to respond_to(:each)
    end

    context "when not defined on class level" do
      subject do
        test_grid do
          column(:id)
        end
      end

      it "raises ConfigurationError" do
        expect do
          subject.scope
        end.to raise_error(Datagrid::ConfigurationError)
      end
    end
  end

  describe ".batch_size" do
    context "when not defined on class level" do
      it "returns 1000" do
        expect(subject.batch_size).to eq(1000)
      end
    end

    context "when defined in the grid class" do
      subject do
        test_grid do
          self.batch_size = 25
        end
      end

      it "returns the configured batch size" do
        expect(subject.batch_size).to eq(25)
      end
    end

    context "when set to nil in the grid class" do
      subject do
        test_grid do
          self.batch_size = nil
        end
      end

      it "returns nil" do
        expect(subject.batch_size).to be_nil
      end
    end
  end

  it "deprecates inclusion of Datagrid module" do
    silence_deprecator do
      class DeprecatedInclusion
        include Datagrid
        scope { Entry }
        column(:name)
      end
    end
    grid = DeprecatedInclusion.new
    expect(grid.data).to eq([["Name"], ["Star"]])
  end
end
