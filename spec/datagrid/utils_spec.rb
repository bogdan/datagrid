require 'spec_helper'

describe Datagrid::Utils do
  

  describe ".warn_once" do
    it "should work" do
      silence_warnings do
        expect(Datagrid::Utils.warn_once("hello", 0.2)).to eq(true)
      end
      sleep(0.1)
      expect(Datagrid::Utils.warn_once("hello", 0.2)).to eq(false)
      sleep(0.2)
      silence_warnings do
        expect(Datagrid::Utils.warn_once("hello", 0.2)).to eq(true)
      end
    end
  end
end
