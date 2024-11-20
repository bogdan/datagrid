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
end
