require 'spec_helper'

describe Datagrid::Utils do
  

  describe ".warn_once" do
    it "should work" do
      silence_warnings do
        Datagrid::Utils.warn_once("hello", 0.2).should be_true
      end
      sleep(0.1)
      Datagrid::Utils.warn_once("hello", 0.2).should be_false
      sleep(0.2)
      silence_warnings do
        Datagrid::Utils.warn_once("hello", 0.2).should be_true
      end
    end
  end
end
