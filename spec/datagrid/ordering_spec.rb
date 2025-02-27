# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Ordering do
  let!(:third) { Entry.create!(name: "cc") }
  let!(:second) { Entry.create!(name: "bb") }
  let!(:first) { Entry.create!(name: "aa") }

  it "supports order" do
    expect(test_grid(order: "name") do
      scope do
        Entry
      end
      column :name
    end.assets).to eq([first, second, third])
  end

  it "supports desc order" do
    expect(test_grid(order: "name", descending: true) do
      scope do
        Entry
      end
      column :name
    end.assets).to eq([third, second, first])
  end

  it "raises error if ordered by not existing column" do
    expect do
      test_grid(order: :hello).assets
    end.to raise_error(Datagrid::OrderUnsupported)
  end

  it "raises error if ordered by column without order" do
    expect do
      test_grid(order: :category) do
        filter(:category, :default, order: false) do |_value|
          self
        end
      end.assets
    end.to raise_error(Datagrid::OrderUnsupported)
  end

  it "overrides default order" do
    expect(test_grid(order: :name) do
      scope { Entry.order("name desc") }
      column(:name, order: "name asc")
    end.assets).to eq([first, second, third])
  end

  it "supports order given as block" do
    expect(test_grid(order: :name) do
      scope { Entry }
      column(:name, order: proc { order("name desc") })
    end.assets).to eq([third, second, first])
  end

  it "supports reversing order given as block" do
    expect(test_grid(order: :name, descending: true) do
      scope { Entry }
      column(:name, order: proc { order("name desc") })
    end.assets).to eq([first, second, third])
  end

  it "supports order desc given as block" do
    expect(test_grid(order: :name, descending: true) do
      scope { Entry }
      column(:name, order_desc: proc { order("name desc") })
    end.assets).to eq([third, second, first])
  end

  it "treats true order as default" do
    expect(test_grid(order: :name) do
      scope { Entry }
      column(:name, order: true)
    end.assets).to eq([first, second, third])
  end

  it "supports order_by_value" do
    report = test_grid(order: :the_name) do
      scope { Entry }
      column(:the_name, order_by_value: true) do
        name
      end
    end
    expect(report.assets).to eq([first, second, third])
    report.descending = true
    expect(report.assets).to eq([third, second, first])
  end

  it "supports order_by_value as block" do
    order = { aa: 2, bb: 3, cc: 1 }
    report = test_grid(order: :the_name) do
      scope { Entry }
      column(:the_name, order_by_value: proc { |model| order[model.name.to_sym] }) do
        name
      end
    end
    expect(report.assets).to eq([third, first, second])
    report.descending = true
    expect(report.assets).to eq([second, first, third])
  end

  it "works correctly with inherited classes" do
    class OrderInheritenceBase < Datagrid::Base
      scope { Entry }
    end

    class OrderInheritenceChild < OrderInheritenceBase
      column(:name)
    end

    grid = OrderInheritenceChild.new(order: "name")
    expect(grid.assets).to eq([first, second, third])
    grid.descending = true
    expect(grid.assets).to eq([third, second, first])
  end

  it "supports ordering by dynamic columns" do
    report = test_grid(order: "name") do
      scope { Entry }
      dynamic do
        column(:name)
      end
    end

    expect(report.assets).to eq([first, second, third])
  end

  it "supports #ordered_by? method" do
    report = test_grid(order: "name") do
      scope  { Entry }
      column(:id)
      column(:name)
    end
    expect(report).to be_ordered_by(:name)
    expect(report).to be_ordered_by("name")
    expect(report).to be_ordered_by(report.column_by_name(:name))
    expect(report).not_to be_ordered_by(:id)
    expect(report).not_to be_ordered_by("id")
    expect(report).not_to be_ordered_by(report.column_by_name(:id))
  end
end
