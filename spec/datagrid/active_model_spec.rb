require 'spec_helper'

describe Datagrid::ActiveModel do

  class ActiveReport
    include Datagrid::ActiveModel
  end

  describe ".model_name" do
    it "should be generate from class name " do
      ActiveReport.model_name.should == "ActiveReport"
    end
    it "should have ActiveModel naming conventions" do
      ActiveReport.model_name.i18n_key.should == :active_report
    end
  end

  
end
