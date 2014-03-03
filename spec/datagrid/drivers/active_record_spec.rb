require 'spec_helper'

describe Datagrid::Drivers::ActiveRecord do

  describe ".match?" do
    subject { described_class }

    it {should be_match(Entry)}
    it {should be_match(Entry.scoped)}
    it {should_not be_match(MongoidEntry)}
  end

  it "should convert any scope to AR::Relation" do
    subject.to_scope(Entry).should be_a(ActiveRecord::Relation)
    subject.to_scope(Entry.limit(5)).should be_a(ActiveRecord::Relation)
    subject.to_scope(Group.create!.entries).should be_a(ActiveRecord::Relation)
  end

  it "should support specifying select options in columns" do
    Entry.create!
    a = subject.to_scope(Entry.group(:name), [Datagrid::Columns::Column.new(SimpleReport, :sum_id, {:select => 'sum(entries.id) sum_id'})])
    a.first.sum_id.should == 1
  end
end
