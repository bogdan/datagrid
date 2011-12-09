require 'spec_helper'

describe Datagrid::Utils do
  

  describe ".warn_once" do
    it "should work" do
      silence_warnings do
        Datagrid::Utils.warn_once("hello").should be_true
      end
      Datagrid::Utils.warn_once("hello").should be_false
    end
  end
end
