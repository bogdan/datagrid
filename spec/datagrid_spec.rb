require 'spec_helper'


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
      subject.attributes.should == {
        :order=>nil, :name=>"Star", :group_id=>group.id,  :disabled => false, :confirmed => false, :category => "first"
      }  
    end

  end

end
