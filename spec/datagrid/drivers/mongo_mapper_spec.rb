describe Datagrid::Drivers::MongoMapper do

  describe ".match?" do
    
    subject { described_class }

    it {should be_match(MongoMapperEntry)}
    # MongoMapper doesn't have a scoped method, instead it has a query method which returns a Plucky::Query object
    it {should be_match(MongoMapperEntry.query)}
    it {should_not be_match(Entry.scoped)}

  end
  describe "api" do
  
    subject do
      MongoMapperGrid.new(
        defined?(_attributes) ? _attributes : {}
      )
    end
  
    let!(:first) do
      MongoMapperEntry.create!(
        :group_id => 2,
        :name => "Main First",
        :disabled => false
      )
    end
    let!(:second) do
      MongoMapperEntry.create!(
        :group_id => 3,
        :name => "Main Second",
        :disabled => true
      )
    end
  
  
    its(:assets) {should include(first, second)}
      
    its(:"assets.size") {should == 2}
    its(:rows) {should == [["Main First", 2, false], ["Main Second", 3, true]]}
    its(:header) {should ==[ "Name", "Group", "Disabled"]}
      
    its(:data) {should == [[ "Name", "Group", "Disabled"], ["Main First", 2, false], ["Main Second", 3, true]]}
      
      
    describe "when some filters specified" do
      let(:_attributes) { {:from_group_id => 3} }
      its(:assets) {should_not include(first)}
      its(:assets) {should include(second)}
    end
      
    describe "when reverse ordering is specified" do
      let(:_attributes) { {:order => :name, :descending => true} }
      its(:rows) {should == [["Main Second", 3, true], ["Main First", 2, false]]}
    end
  end
end
