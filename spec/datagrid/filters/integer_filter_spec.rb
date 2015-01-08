require 'spec_helper'

describe Datagrid::Filters::IntegerFilter do


  let(:entry1) { Entry.create!(:group_id => 1) }
  let(:entry2) { Entry.create!(:group_id => 2) }
  let(:entry3) { Entry.create!(:group_id => 3) }
  let(:entry4) { Entry.create!(:group_id => 4) }
  let(:entry5) { Entry.create!(:group_id => 5) }
  let(:entry7) { Entry.create!(:group_id => 7) }

  it "should support integer range argument" do
    report = test_report(:group_id => 3..5) do
      scope { Entry } 
      filter(:group_id, :integer)
    end
    expect(report.assets).not_to include(entry1)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry7)
  end

  it "should support integer range given as array argument" do
    report = test_report(:group_id => [3.to_s, 5.to_s]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    expect(report.assets).not_to include(entry7)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry1)
  end

  it "should support minimum integer argument" do
    report = test_report(:group_id => [5.to_s, nil]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    expect(report.assets).not_to include(entry1)
    expect(report.assets).not_to include(entry4)
    expect(report.assets).to include(entry7)
  end

  it "should support maximum integer argument" do
    report = test_report(:group_id => [nil, 5.to_s]) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry7)
  end

  it "should find something in one integer interval" do

    report = test_report(:group_id => (4..4)) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    expect(report.assets).not_to include(entry7)
    expect(report.assets).to include(entry4)
    expect(report.assets).not_to include(entry1)
  end
  it "should support invalid range" do

    report = test_report(:group_id => (7..1)) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true)
    end
    expect(report.assets).not_to include(entry7)
    expect(report.assets).not_to include(entry4)
    expect(report.assets).not_to include(entry1)
  end


  it "should support block" do
    report = test_report(:group_id => 5) do
      scope { Entry } 
      filter(:group_id, :integer, :range => true) do |value|
        where("group_id >= ?", value)
      end
    end
    expect(report.assets).not_to include(entry1)
    expect(report.assets).to include(entry5)
  end


  it "should not prefix table name if column is joined" do
    report = test_report(:rating => [4,nil]) do
      scope { Entry.joins(:group) } 
      filter(:rating, :integer, :range => true)
    end
    expect(report.rating).to eq([4,nil])
    expect(report.assets).not_to include(Entry.create!(:group => Group.create!(:rating => 3)))
    expect(report.assets).to include(Entry.create!(:group => Group.create!(:rating => 5)))
  end

  it "should support multiple values" do
    report = test_report(:group_id => "1,2") do
      scope {Entry}
      filter(:group_id, :integer, :multiple => true)
    end
    expect(report.group_id).to eq([1,2])
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
    expect(report.assets).not_to include(entry3)
  end
  it "should support custom separator multiple values" do
    report = test_report(:group_id => "1|2") do
      scope {Entry}
      filter(:group_id, :integer, :multiple => '|')
    end
    expect(report.group_id).to eq([1,2])
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
    expect(report.assets).not_to include(entry3)
  end
  
  it "should support multiple with allow_blank allow_nil options" do
    report  = test_report do
      scope {Entry}
      filter(:group_id, :integer, :multiple => true, :allow_nil => false, :allow_blank => true )
    end
    report.group_id = []
    expect(report.assets).to_not include(entry1)
    expect(report.assets).to_not include(entry2)
    report.group_id = [1]
    expect(report.assets).to include(entry1)
    expect(report.assets).to_not include(entry2)
    report.group_id = nil
    expect(report.assets).to include(entry1)
    expect(report.assets).to include(entry2)
  end
end
