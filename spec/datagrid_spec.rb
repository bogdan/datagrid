require 'spec_helper'
require "datagrid/rspec"


describe SimpleReport do
  
  it_should_behave_like 'Datagrid'
  
  let(:group) { Group.create!(:name => "Pop") }
  
  subject do
    SimpleReport.new(
      :group_id => group.id,
      :name => "Star",
      :category => "first",
      :disabled => false,
      :confirmed => false
    )
  end

  let!(:entry) {  Entry.create!(
    :group => group, :name => "Star", :disabled => false, :confirmed => false, :category => "first"
  ) }

  its(:assets) { should include(entry) }

  describe ".attributes" do
    it "should return report attributes" do
      (subject.filters.map(&:name) + [:order, :descending]).each do |attribute|
        subject.attributes.should have_key(attribute)
      end
    end

  end

  describe ".scope" do
    it "should return defined scope of objects" do
      subject.scope.should respond_to(:each)
    end
      

    context "when not defined on class level" do
      subject do
        test_report {}
      end

      it "should raise ConfigurationError" do
        lambda {
          subject.scope
        }.should raise_error(Datagrid::ConfigurationError)

      end
    end
  end

  describe ".batch_size" do
    context "when not defined on class level" do
      it "returns nil" do
        subject.batch_size.should == nil
      end
    end

    context "when defined in the grid class" do
      subject do
        test_report do
          self.batch_size = 25
        end
      end

      it "returns the configured batch size" do
        subject.batch_size.should == 25
      end
    end

  end


end
