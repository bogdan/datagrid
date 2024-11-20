# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Drivers::Array do
  describe ".match?" do
    subject { described_class }

    it { is_expected.to be_match([]) }
    it { is_expected.to be_match(ActiveRecord::Result.new([], [])) }
    it { is_expected.not_to be_match({}) }
  end

  describe "api" do
    class ArrayGrid < Datagrid::Base
      User = Struct.new(:name, :age)
      scope do
        []
      end

      filter(:name)
      filter(:age, :integer, range: true)

      column(:name)
      column(:age)
    end

    subject do
      ArrayGrid.new(_attributes).scope do
        [first, second, third]
      end
    end

    let(:first) { ArrayGrid::User.new("Vasya", 15) }
    let(:second) { ArrayGrid::User.new("Petya", 12) }
    let(:third) { ArrayGrid::User.new("Vova", 13) }
    let(:_attributes) { {} }

    describe "#assets" do
      subject { super().assets }

      describe "#size" do
        subject { super().size }

        it { is_expected.to eq(3) }
      end
    end

    describe "#rows" do
      subject { super().rows }

      it { is_expected.to eq([["Vasya", 15], ["Petya", 12], ["Vova", 13]]) }
    end

    describe "#header" do
      subject { super().header }

      it { is_expected.to eq(%w[Name Age]) }
    end

    describe "#data" do
      subject { super().data }

      it { is_expected.to eq([%w[Name Age], ["Vasya", 15], ["Petya", 12], ["Vova", 13]]) }
    end

    describe "when some filters specified" do
      let(:_attributes) { { age: [12, 14] } }

      describe "#assets" do
        subject { super().assets }

        it { is_expected.not_to include(first) }
      end

      describe "#assets" do
        subject { super().assets }

        it { is_expected.to include(second) }
      end

      describe "#assets" do
        subject { super().assets }

        it { is_expected.to include(third) }
      end
    end

    describe "when reverse ordering is specified" do
      let(:_attributes) { { order: :name, descending: true } }

      describe "#assets" do
        subject { super().assets }

        it { is_expected.to eq([third, first, second]) }
      end
    end
  end

  describe "when using enumerator scope" do
    it "works fine" do
      grid = test_grid(to_enum: true) do
        scope { [] }
        filter(:to_enum, :boolean) do |_, scope|
          scope.to_enum
        end
      end
      grid.assets.should_not be_any
    end
  end

  describe "array of hashes" do
    class HashGrid < Datagrid::Base
      scope do
        [{ name: "Bogdan", age: 30 }, { name: "Brad", age: 32 }]
      end

      filter(:name)
      filter(:age, :integer, range: true)

      column(:name)
      column(:age)
    end

    subject do
      HashGrid.new(_attributes)
    end

    let(:_attributes) { {} }

    context "ordered" do
      let(:_attributes) { { order: :name, descending: true } }

      it { subject.assets.should == [{ name: "Brad", age: 32 }, { name: "Bogdan", age: 30 }] }
    end
  end
end
