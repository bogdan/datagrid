# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Drivers::ActiveRecord do
  describe ".match?" do
    subject { described_class }

    it { is_expected.to be_match(Entry) }
    it { is_expected.to be_match(Entry.where(id: 1)) }
    it { is_expected.not_to be_match(MongoidEntry) }
  end

  it "converts any scope to AR::Relation" do
    expect(subject.to_scope(Entry)).to be_a(ActiveRecord::Relation)
    expect(subject.to_scope(Entry.limit(5))).to be_a(ActiveRecord::Relation)
    expect(subject.to_scope(Group.create!.entries)).to be_a(ActiveRecord::Relation)
  end

  it "supports append_column_queries" do
    scope = subject.append_column_queries(
      Entry.where({}),
      [Datagrid::Columns::Column.new(test_grid_class, :sum_group_id, "sum(entries.group_id)")],
    )
    expect(scope.to_sql.strip).to eq('SELECT "entries".*, sum(entries.group_id) AS sum_group_id FROM "entries"')
  end

  describe "Arel" do
    subject do
      test_grid(order: :test, descending: true) do
        scope { Entry }
        column(:test, order: Entry.arel_table[:group_id].count)
      end.assets
    end

    it "supports ordering by Arel columns" do
      expect(subject.to_sql.strip).to include 'ORDER BY COUNT("entries"."group_id") DESC'
    end
  end

  describe "when providing blank dynamic fields with include_blank" do
    subject do
      test_grid(name: entry.name, condition1: { field: "", operator: "eq", value: "test" }) do
        scope { Entry }

        filter(:name)
        filter(
          :condition1, :dynamic,
          operators: %w[eq not_eq], include_blank: true, select: %w[name category access_level],
        )
      end.assets
    end

    let(:entry) { Entry.create!(name: "test") }

    it "still applies other filters without raising errors" do
      expect(subject).to eq([entry])
    end
  end

  describe "where by timestamp" do
    subject do
      test_grid(created_at: 10.days.ago..5.days.ago) do
        scope { Entry }

        filter(:created_at, :date, range: true) do |value, scope, _grid|
          scope.joins(:group).where(groups: { created_at: value })
        end
      end.assets
    end

    it "includes object created in proper range" do
      expect(subject).to include(
        Entry.create!(group: Group.create!(created_at: 7.days.ago)),
      )
    end

    it "excludes object created before the range" do
      expect(subject).not_to include(
        Entry.create!(created_at: 7.days.ago, group: Group.create!(created_at: 11.days.ago)),
      )
    end

    it "excludes object created after the range" do
      expect(subject).not_to include(
        Entry.create!(created_at: 7.days.ago, group: Group.create!(created_at: 4.days.ago)),
      )
    end
  end

  describe "batches usage" do
    it "is incompatible with scope with limit" do
      report = test_grid do
        scope { Entry.limit(5) }
        self.batch_size = 20
        column(:id)
      end
      expect { report.data }.to raise_error(Datagrid::ConfigurationError)
    end
  end
end
