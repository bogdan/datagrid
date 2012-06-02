require 'spec_helper'

describe Datagrid::Filters::FloatFilter do
  
  it "should support float values" do
    g1 = Group.create!(:rating => 1.5)
    g2 = Group.create!(:rating => 1.6)
    report = test_report(:rating => 1.5) do
      scope { Group }
      filter(:rating, :float)
    end
    report.assets.should include(g1)
    report.assets.should_not include(g2)
  end
end
