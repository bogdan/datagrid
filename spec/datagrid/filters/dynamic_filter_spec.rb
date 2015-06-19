require "spec_helper" 


describe Datagrid::Filters::DynamicFilter do
  let(:report) do
    test_report do
      scope  {Entry}
      filter(:condition, :dynamic)
    end
  end

  it "should support = operation" do
    report.condition = [:name, "=", "hello"]
    expect(report.assets).to include(Entry.create!(:name => 'hello'))
    expect(report.assets).not_to include(Entry.create!(:name => 'bye'))
  end

  it "should support >= operation" do
    report.condition = [:name, ">=", "d"]
    expect(report.assets).to include(Entry.create!(:name => 'x'))
    expect(report.assets).to include(Entry.create!(:name => 'd'))
    expect(report.assets).not_to include(Entry.create!(:name => 'a'))
  end

  it "should blank value" do
    report.condition = [:name, "=", ""]
    expect(report.assets).to include(Entry.create!(:name => 'hello'))
  end

  it "should support =~ operation on strings" do
    report.condition = [:name, "=~", "ell"]
    expect(report.assets).to include(Entry.create!(:name => 'hello'))
    expect(report.assets).not_to include(Entry.create!(:name => 'bye'))
  end

  it "should support =~ operation integers" do
    report.condition = [:group_id, "=~", 2]
    expect(report.assets).to include(Entry.create!(:group_id => 2))
    expect(report.assets).not_to include(Entry.create!(:group_id => 1))
    expect(report.assets).not_to include(Entry.create!(:group_id => 3))
  end

  it "should support >= operation on integer" do
    report.condition = [:group_id, ">=", 2]
    expect(report.assets).to include(Entry.create!(:group_id => 3))
    expect(report.assets).not_to include(Entry.create!(:group_id => 1))
  end

  it "should support <= operation on integer" do
    report.condition = [:group_id, "<=", 2]
    expect(report.assets).to include(Entry.create!(:group_id => 1))
    expect(report.assets).not_to include(Entry.create!(:group_id => 3))
  end

  it "should support <= operation on integer with string value" do
    report.condition = [:group_id, "<=", '2']
    expect(report.assets).to include(Entry.create!(:group_id => 1))
    expect(report.assets).to include(Entry.create!(:group_id => 2))
    expect(report.assets).not_to include(Entry.create!(:group_id => 3))
  end

  it "should nullify incorrect value for integer" do
    report.condition = [:group_id, "<=", 'aa']
    expect(report.condition).to eq([:group_id, "<=", nil])
  end

  it "should nullify incorrect value for date" do
    report.condition = [:shipping_date, "<=", 'aa']
    expect(report.condition).to eq([:shipping_date, "<=", nil])
  end

  it "should nullify incorrect value for datetime" do
    report.condition = [:created_at, "<=", 'aa']
    expect(report.condition).to eq([:created_at, "<=", nil])
  end

  it "should support date comparation operation by timestamp column" do
    report.condition = [:created_at, "<=", '1986-08-05']
    expect(report.condition).to eq([:created_at, "<=", Date.parse('1986-08-05')])
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-04 01:01:01')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 23:59:59')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-06 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-06 23:59:59')))
  end

  it "should support date = operation by timestamp column" do
    report.condition = [:created_at, "=", '1986-08-05']
    expect(report.condition).to eq([:created_at, "=", Date.parse('1986-08-05')])
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-04 23:59:59')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 23:59:59')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:01')))
    #TODO: investigate SQLite issue and uncomment this line
    #report.assets.should include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-06 23:59:59')))
  end

  it "should support date =~ operation by timestamp column" do
    report.condition = [:created_at, "=~", '1986-08-05']
    expect(report.condition).to eq([:created_at, "=~", Date.parse('1986-08-05')])
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-04 23:59:59')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 23:59:59')))
    expect(report.assets).to include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:01')))
    #TODO: investigate SQLite issue and uncomment this line
    #report.assets.should include(Entry.create!(:created_at => Time.parse('1986-08-05 00:00:00')))
    expect(report.assets).not_to include(Entry.create!(:created_at => Time.parse('1986-08-06 23:59:59')))
  end

  it "should support operations for invalid date" do
    report.condition = [:shipping_date, "<=", '1986-08-05']
    expect(report.assets).to include(Entry.create!(:shipping_date => '1986-08-04'))
    expect(report.assets).to include(Entry.create!(:shipping_date => '1986-08-05'))
    expect(report.assets).not_to include(Entry.create!(:shipping_date => '1986-08-06'))
  end
  it "should support operations for invalid date" do
    report.condition = [:shipping_date, "<=", Date.parse('1986-08-05')]
    expect(report.assets).to include(Entry.create!(:shipping_date => '1986-08-04'))
    expect(report.assets).to include(Entry.create!(:shipping_date => '1986-08-05'))
    expect(report.assets).not_to include(Entry.create!(:shipping_date => '1986-08-06'))
  end

  it "should support allow_nil and allow_blank options" do
    grid = test_report do
      scope {Entry}
      filter(:condition, :dynamic, :allow_nil => true, :allow_blank => true, operations: ['>=', '<=']) do |(field, operation, value), scope|
        if value.blank?
          scope.where(disabled: false)
        else
          scope.where("#{field} #{operation} ?", value)
        end
      end
    end

    expect(grid.assets).to_not include(Entry.create!(disabled: true))
    expect(grid.assets).to include(Entry.create!(disabled: false))

    grid.condition = [:group_id, '>=', 3]
    expect(grid.assets).to include(Entry.create!(disabled: true, group_id: 4))
    expect(grid.assets).to_not include(Entry.create!(disabled: false, group_id: 2))
  end

  it "should raise if unknown operation" do
    report.condition = [:shipping_date, "<>", '1996-08-05']
    expect{
      report.assets
    }.to raise_error(Datagrid::FilteringError)
  end

end
