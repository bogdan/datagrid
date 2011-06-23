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
      subject.scope.should respond_to(:table_name)
    end
      

    context "when not defined on class level" do
      before(:each) do
        @scope = SimpleReport.instance_variable_get("@scope")
        SimpleReport.instance_variable_set("@scope", nil)
      end

      after(:each) do
        SimpleReport.instance_variable_set("@scope", @scope)
      end

      it "should raise ConfigurationError" do
        lambda {
          subject.scope
        }.should raise_error(Datagrid::ConfigurationError)
        
      end
    end
  end



end
