require 'spec_helper'

describe Datagrid::Drivers::ActiveRecord do

  describe ".match?" do
    subject { described_class }

    it {should be_match(Entry)}
    it {should be_match(Entry.scoped)}
    it {should_not be_match(MongoidEntry)}
  end
  
end
