require 'spec_helper'

describe Datagrid::Ordering do


  let!(:first) { Entry.create!(:name => "aa")}
  let!(:second) { Entry.create!(:name => "bb")}
  let!(:third) { Entry.create!(:name => "cc")}


  it "should support order" do
    test_report(:order => "name") do
      scope do
        Entry
      end
      column :name
    end.assets.should == [first, second, third]

  end

  it "should support desc order" do
    test_report(:order => "name", :descending => true) do
      scope do
        Entry
      end
      column :name
    end.assets.should == [third, second, first]
  end


  it "should raise error if ordered by not existing column" do
    lambda {
      test_report(:order => :hello)
    }.should raise_error(Datagrid::OrderUnsupported)
  end

  it "should raise error if ordered by column without order" do
    lambda do
      test_report(:order => :category) do
        filter(:category, :default, :order => false) do |value|
          self
        end
      end
    end.should raise_error(Datagrid::OrderUnsupported)
  end

  it "should override default order" do
    test_report(:order => :name) do
      scope { Entry.order("name desc")}
      column(:name, :order => "name asc")
    end.assets.should == [first, second, third]
  end

  it "should support order given as block" do
    test_report(:order => :name) do
      scope { Entry }
      column(:name, :order => proc { order("name desc") })
    end.assets.should == [third, second, first]
  end

  it "should support reversing order given as block" do
    test_report(:order => :name, :descending => true) do
      scope { Entry }
      column(:name, :order => proc { order("name desc") })
    end.assets.should == [first, second, third]
  end

  it "should support order desc given as block" do
    test_report(:order => :name, :descending => true) do
      scope { Entry }
      column(:name,  :order_desc => proc { order("name desc")})
    end.assets.should == [third, second, first]
  end

  it "should treat true order as default" do
    test_report(:order => :name) do
      scope { Entry }
      column(:name,  :order => true)
    end.assets.should == [first, second, third]
  end

  it "should support order_by_value" do
    report = test_report(:order => :the_name) do
      scope {Entry}
      column(:the_name, :order_by_value => true) do
        name
      end
    end
    report.assets.should == [first, second, third]
    report.descending = true
    report.assets.should == [third, second, first]
  end

  it "should support order_by_value as block" do

    order = { :aa => 2, :bb => 3, :cc => 1}
    report = test_report(:order => :the_name) do
      
      scope {Entry}
      column(:the_name, :order_by_value => proc{|model| order[model.name.to_sym]}) do
        name
      end
    end
    report.assets.should == [third, first, second]
    report.descending = true
    report.assets.should == [second, first, third]
  end

end
