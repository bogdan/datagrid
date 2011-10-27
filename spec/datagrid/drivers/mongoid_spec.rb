describe "Datagrid::Drivers::Mongoid" do

  subject { MongoidGrid.new }
  
  let!(:entry) do
    MongoidEntry.create!(
      :group_id => 1,
      :name => "Main",
      :disabled => true
    )
  end

  its(:assets) {should include(entry)}

  its(:rows) {should == [["Main", 1, true]]}
  its(:header) {should ==[ "Name", "Group", "Disabled"]}

  its(:data) {should == [[ "Name", "Group", "Disabled"], ["Main", 1, true]]}

end
