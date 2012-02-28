require 'spec_helper'

describe Datagrid::ActiveModel do

  class ActiveReport
    include Datagrid::ActiveModel
  end

  module Grid
    class ActiveReport
      include Datagrid::ActiveModel
    end
  end

  describe ".model_name" do
    it "should be generate from class name " do
      ActiveReport.model_name.should == "ActiveReport"
    end
    it "should have ActiveModel naming conventions" do
      ActiveReport.model_name.i18n_key.should == :active_report
    end
  end

  describe ".param_name" do
    it "should make right param key from simple class name" do
      ActiveReport.param_name.should == 'active_report'
    end
    it "should make right param key from class of module" do
      Grid::ActiveReport.param_name.should == 'grid_active_report'
    end
  end

end
