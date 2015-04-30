require 'spec_helper'

describe Datagrid::Drivers::ActiveRecord do

  describe ".match?" do
    subject { described_class }

    it {should be_match(Entry)}
    it {should be_match(Entry.where(:id => 1))}
    it {should_not be_match(MongoidEntry)}
  end

  it "should convert any scope to AR::Relation" do
    expect(subject.to_scope(Entry)).to be_a(ActiveRecord::Relation)
    expect(subject.to_scope(Entry.limit(5))).to be_a(ActiveRecord::Relation)
    expect(subject.to_scope(Group.create!.entries)).to be_a(ActiveRecord::Relation)
  end

  it "should support append_column_queries" do
    scope = subject.append_column_queries(Entry.where({}), [Datagrid::Columns::Column.new(test_report_class, :sum_group_id, 'sum(entries.group_id)')])
    expect(scope.to_sql.strip).to eq('SELECT "entries".*, sum(entries.group_id) AS sum_group_id FROM "entries"')
  end
end
