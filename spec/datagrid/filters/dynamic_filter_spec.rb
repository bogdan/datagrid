# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::DynamicFilter do
  let(:report) do
    test_grid_filter(:condition, :dynamic)
  end

  it "supports = operation" do
    report.condition = [:name, "=", "hello"]
    expect(report.assets).to include(Entry.create!(name: "hello"))
    expect(report.assets).not_to include(Entry.create!(name: "bye"))
  end

  it "supports >= operation" do
    report.condition = [:name, ">=", "d"]
    expect(report.assets).to include(Entry.create!(name: "x"))
    expect(report.assets).to include(Entry.create!(name: "d"))
    expect(report.assets).not_to include(Entry.create!(name: "a"))
  end

  it "blanks value" do
    report.condition = [:name, "=", ""]
    expect(report.assets).to include(Entry.create!(name: "hello"))
  end

  it "supports =~ operation on strings" do
    report.condition = [:name, "=~", "ell"]
    expect(report.assets).to include(Entry.create!(name: "hello"))
    expect(report.assets).not_to include(Entry.create!(name: "bye"))
  end

  it "supports =~ operation integers" do
    report.condition = [:group_id, "=~", 2]
    expect(report.assets).to include(Entry.create!(group_id: 2))
    expect(report.assets).not_to include(Entry.create!(group_id: 1))
    expect(report.assets).not_to include(Entry.create!(group_id: 3))
  end

  it "supports >= operation on integer" do
    report.condition = [:group_id, ">=", 2]
    expect(report.assets).to include(Entry.create!(group_id: 3))
    expect(report.assets).not_to include(Entry.create!(group_id: 1))
  end

  it "supports <= operation on integer" do
    report.condition = [:group_id, "<=", 2]
    expect(report.assets).to include(Entry.create!(group_id: 1))
    expect(report.assets).not_to include(Entry.create!(group_id: 3))
  end

  it "supports <= operation on integer with string value" do
    report.condition = [:group_id, "<=", "2"]
    expect(report.assets).to include(Entry.create!(group_id: 1))
    expect(report.assets).to include(Entry.create!(group_id: 2))
    expect(report.assets).not_to include(Entry.create!(group_id: 3))
  end

  it "nullifies incorrect value for integer" do
    report.condition = [:group_id, "<=", "aa"]
    expect(report.condition.to_h).to eq(
      { field: :group_id, operation: "<=", value: nil },
    )
  end

  it "nullifies incorrect value for date" do
    report.condition = [:shipping_date, "<=", "aa"]
    expect(report.condition.to_h).to eq({
      field: :shipping_date, operation: "<=", value: nil,
    })
  end

  it "nullifies incorrect value for datetime" do
    report.condition = [:created_at, "<=", "aa"]
    expect(report.condition.to_h).to eq({ field: :created_at, operation: "<=", value: nil })
  end

  it "supports date comparation operation by timestamp column" do
    report.condition = [:created_at, "<=", "1986-08-05"]
    expect(report.condition.to_h).to eq({ field: :created_at, operation: "<=", value: Date.parse("1986-08-05") })
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-04 01:01:01")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 23:59:59")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 00:00:00")))
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-06 00:00:00")))
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-06 23:59:59")))
  end

  it "supports date = operation by timestamp column" do
    report.condition = [:created_at, "=", "1986-08-05"]
    expect(report.condition.to_h).to eq({ field: :created_at, operation: "=", value: Date.parse("1986-08-05") })
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-04 23:59:59")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 23:59:59")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 00:00:01")))
    # TODO: investigate SQLite issue and uncomment this line
    # report.assets.should include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-06 23:59:59")))
  end

  it "supports date =~ operation by timestamp column" do
    report.condition = [:created_at, "=~", "1986-08-05"]
    expect(report.condition.to_h).to eq({ field: :created_at, operation: "=~", value: Date.parse("1986-08-05") })
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-04 23:59:59")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 23:59:59")))
    expect(report.assets).to include(Entry.create!(created_at: Time.parse("1986-08-05 00:00:01")))
    # TODO: investigate SQLite issue and uncomment this line
    # report.assets.should include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(created_at: Time.parse("1986-08-06 23:59:59")))
  end

  it "supports operations for invalid date" do
    report.condition = [:shipping_date, "<=", "1986-08-05"]
    expect(report.assets).to include(Entry.create!(shipping_date: "1986-08-04"))
    expect(report.assets).to include(Entry.create!(shipping_date: "1986-08-05"))
    expect(report.assets).not_to include(Entry.create!(shipping_date: "1986-08-06"))
  end

  it "supports operations for invalid date" do
    report.condition = [:shipping_date, "<=", Date.parse("1986-08-05")]
    expect(report.assets).to include(Entry.create!(shipping_date: "1986-08-04"))
    expect(report.assets).to include(Entry.create!(shipping_date: "1986-08-05"))
    expect(report.assets).not_to include(Entry.create!(shipping_date: "1986-08-06"))
  end

  it "supports allow_nil and allow_blank options" do
    grid = test_grid_filter(
      :condition, :dynamic, allow_nil: true, allow_blank: true,
      operations: [">=", "<="],
    ) do |(field, operation, value), scope|
      if value.blank?
        scope.where(disabled: false)
      else
        scope.where("#{field} #{operation} ?", value)
      end
    end

    expect(grid.assets).not_to include(Entry.create!(disabled: true))
    expect(grid.assets).to include(Entry.create!(disabled: false))

    grid.condition = [:group_id, ">=", 3]
    expect(grid.assets).to include(Entry.create!(disabled: true, group_id: 4))
    expect(grid.assets).not_to include(Entry.create!(disabled: false, group_id: 2))
  end

  it "supports custom operations" do
    entry = Entry.create!(name: "hello")

    grid = test_grid do
      scope { Entry }
      filter(
        :condition, :dynamic, operations: ["=", "!="],
      ) do |filter, scope|
        if filter.operation == "!="
          scope.where("#{filter.field} != ?", filter.value)
        else
          default_filter
        end
      end
    end

    grid.condition = ["name", "=", "hello"]
    expect(grid.assets).to include(entry)
    grid.condition = ["name", "!=", "hello"]
    expect(grid.assets).not_to include(entry)
    grid.condition = ["name", "=", "hello1"]
    expect(grid.assets).not_to include(entry)
    grid.condition = ["name", "!=", "hello1"]
    expect(grid.assets).to include(entry)
  end

  it "raises if unknown operation" do
    report.condition = [:shipping_date, "<>", "1996-08-05"]
    expect do
      report.assets
    end.to raise_error(Datagrid::FilteringError)
  end

  it "supports assignment of string keys hash" do
    report.condition = {
      field: "shipping_date",
      operation: "<>",
      value: "1996-08-05",
    }.stringify_keys

    expect(report.condition.to_h).to eq({
      field: "shipping_date", operation: "<>", value: Date.parse("1996-08-05"),
    })
  end

  it "supports guessing type of joined column" do
    skip unless defined?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) &&
      Entry.connection.is_a?(::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)

    group = Group.create!(name: "Test Group")
    entry = Entry.create!(name: "Hello World", group:)

    grid = test_grid do
      scope { Entry.joins(:group) }
      filter(
        :condition, :dynamic,
         operations: %w[= =~],
         select: [
           ["Entry Name", "entries.name"],
           ["Group Name", "groups.name"]
         ]
      )
    end

    grid.condition = ["entries.name", "=~", "Hello"]
    expect(grid.assets).to include(entry)

    grid.condition = ["entries.name", "=~", "Test"]
    expect(grid.assets).to_not include(entry)

    grid.condition = ["groups.name", "=~", "Test"]
    expect(grid.assets).to include(entry)

    grid.condition = ["groups.name", "=~", "Hello"]
    expect(grid.assets).to_not include(entry)
  end
end
