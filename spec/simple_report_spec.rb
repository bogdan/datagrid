require 'spec_helper'

describe SimpleReport do
  subject do
    SimpleReport.new(
      :group_id => 1,
      :name => "gg"
    )
  end

  its(:assets) { should_not be_nil }
  

end
