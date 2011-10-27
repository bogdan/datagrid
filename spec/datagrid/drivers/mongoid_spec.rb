describe "Datagrid::Drivers::Mongoid" do

  subject { MongoidGrid.new }
  
  before(:each) do
    MongoidEntry.create!(
      :group_id => 1,
      :name => "Main",
      :disabled => true
    )
  end

  its(:assets) {should_not be_empty}

end
