require 'spec_helper'

describe Datagrid::Drivers::Sequel do

  describe ".match?" do
    
    subject { described_class }

    it {should be_match(SequelEntry)}
    it {should be_match(SequelEntry.where(:id => 1))}
    it {should_not be_match(Entry.where(:id => 1))}

  end
  describe "api" do

    subject do
      SequelGrid.new(
        defined?(_attributes) ? _attributes : {}
      )
    end

    let!(:first) do
      SequelEntry.create(
        :group_id => 2,
        :name => "Main First",
        :disabled => false
      )
    end
    let!(:second) do
      SequelEntry.create(
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
        subject { super().count }
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
        subject { super().assets.map(&:id) }
        it {should_not include(first.id)}
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

    it "should provide default order for non declared fields" do
      expect {
        test_report(:order => :test) do
          scope { SequelEntry }
          column(:test) do
            'test'
          end
        end.assets
      }.to raise_error(Datagrid::OrderUnsupported)
    end

    it "should support batch_size" do
      report = test_report do
        scope { SequelEntry }
        self.batch_size = 1 
        column(:name)
      end

      expect(report.data).to eq([["Name"], ["Main First"], ["Main Second"]])
    end
  end
end
