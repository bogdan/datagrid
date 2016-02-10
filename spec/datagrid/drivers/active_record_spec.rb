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

  describe "Arel" do
    subject do
      test_report(:order => :test, :descending => true) do
        scope { Entry }
        column(:test, order: Arel::Nodes::Count.new(["entries.group_id"]))
      end.assets
    end

    it "should support ordering by Arel columns" do
      expect(subject.to_sql.strip).to include "ORDER BY COUNT('entries.group_id') DESC"
    end
  end

  describe "gotcha #datagrid_where_by_timestamp" do

    subject do
      test_report(created_at: 10.days.ago..5.days.ago) do
        scope {Entry}

        filter(:created_at, :date, range: true) do |value, scope, grid|
          scope.joins(:group).datagrid_where_by_timestamp("groups.created_at", value)
        end
      end.assets
    end
    it "includes object created in proper range" do
      expect(subject).to include(
        Entry.create!(group: Group.create!(created_at: 7.days.ago)),
      )
    end

    it "excludes object created before the range" do
      expect(subject).to_not include(
        Entry.create!(created_at: 7.days.ago, group: Group.create!(created_at: 11.days.ago)),
      )
    end
    it "excludes object created after the range" do
      expect(subject).to_not include(
        Entry.create!(created_at: 7.days.ago, group: Group.create!(created_at: 4.days.ago)),
      )
    end
  end

  describe "batches usage" do

    it "should be incompatible with scope with limit" do
      report = test_report do
        scope {Entry.limit(5)}
        self.batch_size = 20
        column(:id)
      end
      expect { report.data }.to raise_error(Datagrid::ConfigurationError)
    end
  end


end
