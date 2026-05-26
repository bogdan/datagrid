# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Utils do
  describe ".warn_once" do
    it "works" do
      silence_deprecator do
        expect(described_class.warn_once("hello", 0.2)).to be(true)
      end
      sleep(0.1)
      expect(described_class.warn_once("hello", 0.2)).to be(false)
      sleep(0.2)
      silence_deprecator do
        expect(described_class.warn_once("hello", 0.2)).to be(true)
      end
    end
  end

  describe ".select_values" do
    it "returns values from simple array" do
      expect(described_class.select_values([1, 2])).to eq([1, 2])
    end

    it "returns values from pairs" do
      expect(described_class.select_values([["A", 1], ["B", 2]])).to eq([1, 2])
    end

    it "returns values from hash" do
      expect(described_class.select_values({ "A" => 1, "B" => 2 })).to eq([1, 2])
    end

    it "returns empty array for empty options" do
      expect(described_class.select_values([])).to eq([])
      expect(described_class.select_values(nil)).to eq([])
    end

    it "returns values from grouped options" do
      options = [
        ["Group 1", [["A", 1], ["B", 2]]],
        ["Group 2", [["C", 3]]]
      ]
      expect(described_class.select_values(options)).to eq([1, 2, 3])
    end
  end
end
