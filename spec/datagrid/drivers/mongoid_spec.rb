describe Datagrid::Drivers::Mongoid do

  describe "api" do

    subject do
      MongoidGrid.new({
        :group_id => 2,
        :order => :name
      }.merge(defined?(_attributes) ? _attributes : {})) 
    end

    let!(:first) do
      MongoidEntry.create!(
        :group_id => 2,
        :name => "Main First",
        :disabled => false
      )
    end
    let!(:second) do
      MongoidEntry.create!(
        :group_id => 2,
        :name => "Main Second",
        :disabled => false
      )
    end
    let!(:another_entry) do
      MongoidEntry.create!(
        :group_id => 3,
        :name => "Alternative",
        :disabled => true
      )
    end


    its(:assets) {should include(first, second)}

    its(:rows) {should == [["Main First", 2, false], ["Main Second", 2, false]]}
    its(:header) {should ==[ "Name", "Group", "Disabled"]}

    its(:data) {should == [[ "Name", "Group", "Disabled"], ["Main First", 2, false], ["Main Second", 2, false]]}

  end
end
