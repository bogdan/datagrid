require 'spec_helper'

describe SimpleReport do
  
  let(:group) { Group.create!(:name => "Pop") }
  subject do
    SimpleReport.new(
      :group_id => group.id,
      :name => "Star"
    )
  end

  let!(:entry) {  Entry.create!(:group => group, :name => "Star") }

  its(:assets) { should include(entry) }

end
