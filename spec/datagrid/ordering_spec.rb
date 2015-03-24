require 'spec_helper'

describe Datagrid::Ordering do


  let!(:third) { Entry.create!(:name => "cc")}
  let!(:second) { Entry.create!(:name => "bb")}
  let!(:first) { Entry.create!(:name => "aa")}


  it "should support order" do
    expect(test_report(:order => "name") do
      scope do
        Entry
      end
      column :name
    end.assets).to eq([first, second, third])

  end

  it "should support desc order" do
    expect(test_report(:order => "name", :descending => true) do
      scope do
        Entry
      end
      column :name
    end.assets).to eq([third, second, first])
  end


  it "should raise error if ordered by not existing column" do
    expect {
      test_report(:order => :hello).assets
    }.to raise_error(Datagrid::OrderUnsupported)
  end

  it "should raise error if ordered by column without order" do
    expect do
      test_report(:order => :category) do
        filter(:category, :default, :order => false) do |value|
          self
        end
      end.assets
    end.to raise_error(Datagrid::OrderUnsupported)
  end

  it "should override default order" do
    expect(test_report(:order => :name) do
      scope { Entry.order("name desc")}
      column(:name, :order => "name asc")
    end.assets).to eq([first, second, third])
  end

  it "should support order given as block" do
    expect(test_report(:order => :name) do
      scope { Entry }
      column(:name, :order => proc { order("name desc") })
    end.assets).to eq([third, second, first])
  end

  it "should support reversing order given as block" do
    expect(test_report(:order => :name, :descending => true) do
      scope { Entry }
      column(:name, :order => proc { order("name desc") })
    end.assets).to eq([first, second, third])
  end

  it "should support order desc given as block" do
    expect(test_report(:order => :name, :descending => true) do
      scope { Entry }
      column(:name,  :order_desc => proc { order("name desc")})
    end.assets).to eq([third, second, first])
  end

  it "should treat true order as default" do
    expect(test_report(:order => :name) do
      scope { Entry }
      column(:name,  :order => true)
    end.assets).to eq([first, second, third])
  end

  it "should support order_by_value" do
    report = test_report(:order => :the_name) do
      scope {Entry}
      column(:the_name, :order_by_value => true) do
        name
      end
    end
    expect(report.assets).to eq([first, second, third])
    report.descending = true
    expect(report.assets).to eq([third, second, first])
  end

  it "should support order_by_value as block" do

    order = { :aa => 2, :bb => 3, :cc => 1}
    report = test_report(:order => :the_name) do
      
      scope {Entry}
      column(:the_name, :order_by_value => proc{|model| order[model.name.to_sym]}) do
        name
      end
    end
    expect(report.assets).to eq([third, first, second])
    report.descending = true
    expect(report.assets).to eq([second, first, third])
  end

  it "should work correctly with inherited classes" do
    class OrderInheritenceBase
      include Datagrid
      scope { Entry }
    end

    class OrderInheritenceChild < OrderInheritenceBase
      column(:name)
    end

    grid = OrderInheritenceChild.new(order: 'name')
    expect(grid.assets).to eq([first, second, third])
    grid.descending = true
    expect(grid.assets).to eq([third, second, first])
  end
  it "should support ordering by dynamic columns" do

    report = test_report(:order => "name") do
      scope {Entry}
      dynamic do
        column(:name)
      end
    end

    expect(report.assets).to eq([first, second, third])

  end

  it "should support #ordered_by? method" do
    report = test_report(:order => "name") do
      scope  {Entry}
      column(:id)
      column(:name)
    end
    expect(report).to be_ordered_by(:name)
    expect(report).to be_ordered_by("name")
    expect(report).to be_ordered_by(report.column_by_name(:name))
    expect(report).to_not be_ordered_by(:id)
    expect(report).to_not be_ordered_by("id")
    expect(report).to_not be_ordered_by(report.column_by_name(:id))
  end
end
