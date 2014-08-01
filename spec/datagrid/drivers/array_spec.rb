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
  
          
    describe '#assets' do
      subject { super().assets }
      describe '#size' do
        subject { super().size }
        it {should == 3}
      end
    end

    describe '#rows' do
      subject { super().rows }
      it {should == [["Vasya", 15], ["Petya", 12], ["Vova", 13]]}
    end

    describe '#header' do
      subject { super().header }
      it {should ==[ "Name", "Age"]}
    end
      
    describe '#data' do
      subject { super().data }
      it {should == [[ "Name", "Age"], ["Vasya", 15], ["Petya", 12], ["Vova", 13]]}
    end
      
      
    describe "when some filters specified" do
      let(:_attributes) { {:age => [12,14]} }

      describe '#assets' do
        subject { super().assets }
        it {should_not include(first)}
      end

      describe '#assets' do
        subject { super().assets }
        it {should include(second)}
      end

      describe '#assets' do
        subject { super().assets }
        it {should include(third)}
      end
    end
      
    describe "when reverse ordering is specified" do
      let(:_attributes) { {:order => :name, :descending => true} }

      describe '#assets' do
        subject { super().assets }
        it {should == [third, first, second]}
      end
    end

  end
    describe "when using enumerator scope" do

      it "should work fine" do
        grid = test_report(to_enum: true) do
          scope {[]}
          filter(:to_enum, :boolean) do |_, scope|
            scope.to_enum
          end
        end
        grid.assets.should_not be_any
      end
    end
end
