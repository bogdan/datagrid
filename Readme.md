## Datagrid

Ruby library that helps you to build and repsend table like data with:

* Filtering
* Sort order
* Exportort to CSV


### Grid DSL

In order to create a report You need to define:

* scope of ActiveRecord objects to look through
* filters that will be used to filter data
* columns that should be displayed and sortable(if possible)


``` ruby

class SimpleReport

  include Datagrid


  scope do
    User.includes(:group)
  end

  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :eboolean)
  filter(:confirmed, :boolean)
  integer_range_filter(:logins_count, :integer)
  filter(:group_name) do |value|
    self.joins(:group).where(:groups => {:name => value})
  end

  column(:group, :order => "groups.name") do |model|
    group.name
  end

  column(:name)


end


report = SimpleReport.new(:group_id => 5, :from_logins_count => 1)
report.assets # => Array of User: SELECT * FROM users WHERE users.group_id = 5 AND users.logins_count >= 1
report.header
report.rows
report.data

```

### Filters

Datagrid supports different type of filters including:

* text
* integer
* date
* boolean
* eboolean - the select of "yes", "no" and any
* enum


