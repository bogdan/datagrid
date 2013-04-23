require 'spec_helper'

describe Datagrid::Drivers::Array do

  describe ".match?" do
    subject { described_class }

    it {should be_match(Array.new)}
    it {should_not be_match({})}
  end
  
  describe "api" do
  
    class ArrayGrid
      class User < Struct.new(:name, :age); end
      include Datagrid
      scope do
        []
      end

      filter(:name)
      filter(:age, :integer, :range => true)

      column(:name)
      column(:age)
    end

    let(:first) { ArrayGrid::User.new("Vasya", 15) }
    let(:second) { ArrayGrid::User.new("Petya", 12) }
    let(:third) { ArrayGrid::User.new("Vova", 13) }

    subject do
      ArrayGrid.new(
        defined?(_attributes) ? _attributes : {}
      ).scope do
        [ first, second, third ]
      end
    end
  
          
    its(:"assets.size") {should == 3}
    its(:rows) {should == [["Vasya", 15], ["Petya", 12], ["Vova", 13]]}
    its(:header) {should ==[ "Name", "Age"]}
      
    its(:data) {should == [[ "Name", "Age"], ["Vasya", 15], ["Petya", 12], ["Vova", 13]]}
      
      
    describe "when some filters specified" do
      let(:_attributes) { {:age => [12,14]} }
      its(:assets) {should_not include(first)}
      its(:assets) {should include(second)}
      its(:assets) {should include(third)}
    end
      
    describe "when reverse ordering is specified" do
      let(:_attributes) { {:order => :name, :descending => true} }
      its(:assets) {should == [third, first, second]}
    end
  end
end
