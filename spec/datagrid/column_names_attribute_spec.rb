# frozen_string_literal: true

require "spec_helper"

describe Datagrid::ColumnNamesAttribute do
  subject { report }

  let(:column_names_filter_options) do
    {}
  end
  let!(:entry) do
    Entry.create!(name: "hello", category: "greeting")
  end

  let(:report) do
    options = column_names_filter_options
    test_grid do
      scope { Entry }
      column_names_filter(**options)
      column(:id)
      column(:name, mandatory: true)
      column(:category)
    end
  end

  it "works" do
    subject.column_names = [:id]
    expect(subject.mandatory_columns.map(&:name)).to eq([:name])
    expect(subject.optional_columns.map(&:name)).to eq(%i[id category])
    expect(subject.data).to eq([%w[Id Name], [entry.id, "hello"]])
    columns_filter = subject.filter_by_name(:column_names)
    expect(columns_filter).not_to be_nil
    expect(columns_filter.select(subject)).to eq([["Id", :id], ["Category", :category]])
  end

  it "shows only mandatory columns by default" do
    expect(subject.row_for(entry)).to eq(["hello"])
    subject.column_names = %w[name category]
    expect(subject.row_for(entry)).to eq(%w[hello greeting])
  end

  it "shows mandatory columns even if they are unselected" do
    subject.column_names = ["category"]
    expect(subject.row_for(entry)).to eq(%w[hello greeting])
    expect(subject.data).to eq([%w[Name Category], %w[hello greeting]])
  end

  it "finds any column by name" do
    expect(subject.column_by_name(:id)).not_to be_nil
    expect(subject.column_by_name(:name)).not_to be_nil
    expect(subject.column_by_name(:category)).not_to be_nil
  end

  context "when default option is passed to column_names_filter" do
    let(:column_names_filter_options) do
      { default: [:id] }
    end

    describe "#data" do
      subject { super().data }

      it { is_expected.to eq([%w[Id Name], [entry.id, "hello"]]) }
    end
  end

  context "when some columns are disabled" do
    subject do
      test_grid do
        scope { Entry }
        column(:id, mandatory: true)
        column(:name)
        column(:category, if: proc { false })
        column(:group, mandatory: true, if: proc { false })
      end
    end

    it "excludes them from mandatory_columns" do
      expect(subject.mandatory_columns.map(&:name)).to eq([:id])
    end

    it "excludes them from optional_columns" do
      expect(subject.optional_columns.map(&:name)).to eq([:name])
    end
  end
end
