require "spec_helper"

describe Datagrid::Drivers::MongoMapper, :mongomapper do

  describe ".match?" do
    
    subject { described_class }

    it {should be_match(MongoMapperEntry)}
    # MongoMapper doesn't have a scoped method, instead it has a query method which returns a Plucky::Query object
    it {should be_match(MongoMapperEntry.query)}
    it {should_not be_match(Entry.where(:id => 1))}

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
  
  
    describe '#assets' do
      subject { super().assets }
      it {should include(first, second)}
    end
      
    describe '#assets' do
      subject { super().assets }
      describe '#size' do
        subject { super().size }
        it {should == 2}
      end
    end

    describe '#rows' do
      subject { super().rows }
      it {should == [["Main First", 2, false], ["Main Second", 3, true]]}
    end

    describe '#header' do
      subject { super().header }
      it {should ==[ "Name", "Group", "Disabled"]}
    end
      
    describe '#data' do
      subject { super().data }
      it {should == [[ "Name", "Group", "Disabled"], ["Main First", 2, false], ["Main Second", 3, true]]}
    end
      
      
    describe "when some filters specified" do
      let(:_attributes) { {:from_group_id => 3} }

      describe '#assets' do
        subject { super().assets }
        it {should_not include(first)}
      end

      describe '#assets' do
        subject { super().assets }
        it {should include(second)}
      end
    end
      
    describe "when reverse ordering is specified" do
      let(:_attributes) { {:order => :name, :descending => true} }

      describe '#rows' do
        subject { super().rows }
        it {should == [["Main Second", 3, true], ["Main First", 2, false]]}
      end
    end
    it "should not provide default order for non declared fields" do
      expect {
        test_report(:order => :test) do
          scope { MongoMapperEntry }
          column(:test)
        end.assets
      }.to raise_error(Datagrid::OrderUnsupported)
    end
  end
end
