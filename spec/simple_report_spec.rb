require 'spec_helper'

class SimpleReport

  include Datagrid

  filter(:group_id)
  filter(:name) do |value|
    self.scoped(:conditions => {:name => value})
  end

  column(:group) do |model|
    Group.find(model.group_id)
  end

  column(:name)

  def scope
    Entry
  end
end

describe SimpleReport do
  
  it_should_behave_like 'Datagrid'
  let(:group) { Group.create!(:name => "Pop") }
  subject do
    SimpleReport.new(
      :group_id => group.id,
      :name => "Star"
    )
  end

  let!(:entry) {  Entry.create!(:group => group, :name => "Star") }

  its(:assets) { should include(entry) }

  describe ".attributes" do
    it "should return report attributes" do
      subject.attributes.should == {:order=>nil, :name=>"Star", :group_id=>5}  
    end

  end

end
