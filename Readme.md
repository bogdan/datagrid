# Datagrid

Ruby library that helps you to build and repsend table like data with:

* Customizable filtering
* Columns
* Sort order
* Localization
* Exportort to CSV


### Grid DSL

In order to create a report You need to define:

* scope of ActiveRecord objects to look through
* filters that will be used to filter data
* columns that should be displayed and sortable(if possible)


### Working grid example

In order to create a grid:

``` ruby

class SimpleReport

  include Datagrid


  scope do
    User.includes(:group)
  end

  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :eboolean)
  filter(:confirmed, :boolean)
  filter(:group_id, :multiple => true)
  integer_range_filter(:logins_count, :integer)
  filter(:group_name, :header => "Group") do |value|
    self.joins(:group).where(:groups => {:name => value})
  end


  column(:name)
  column(:group, :order => "groups.name") do |user|
    user.name
  end
  column(:active, :header => "Activated") do |user|
    !user.disabled
  end



end


```

Basic grid api:

``` ruby
report = SimpleReport.new(:order => "group", :reverse => true, :group_id => [1,2], :from_logins_count => 1, :category => "first")

report.assets # => Array of User instances: 
              # SELECT * FROM users WHERE users.group_id in (1,2) AND users.logins_count >= 1 AND users.category = 'first' ORDER BY groups.name DESC

report.header # => ["Group", "Name", "Disabled"]
report.rows   # => [
              #      ["Steve", "Spammers", true],
              #      [ "John", "Spoilers", true],
              #      ["Berry", "Good people", false]
              #    ]
report.data   # => [ header, *rows]

report.to_csv # => Yes, it is
```

### Scope

Default scope of objects to filter and display.
In common case it is `ActiveRecord::Base` subclass with some generic scopes like in example above.

### Filters

Each filter definition consists of:

* name of the filter
* type that will be used for value typecast
* conditions block that applies to defined scope
* additional options

Datagrid supports different type of filters including:

* text
* integer
* date
* boolean
* eboolean - the select of "yes", "no" and any
* enum

Read more about filters here:


### Columns

Each column is represented by name and code block to calculate the value.
Grids are sortable by it's columns. Ordering is controller by `#order` and `#reverse` attributes.

More information about columns here:



