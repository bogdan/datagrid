# Datagrid

Ruby library that helps you to build and represent table-like data with:

* Customizable filtering
* Columns
* Sort order
* Localization
* Export to CSV


*NOTE:* This gem is still under heavy development. If you find a bug, don't consider this a piece of shit; just report it and I'll fix it shortly. 

*This is not trivial stuff, so I really need your help guys.*


### Grid DSL

In order to create a report, you need to define:

* scope of ActiveRecord objects to look through
* filters that will be used to filter data
* columns that should be displayed and sortable (if possible)


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
  filter(:group_id, :integer, :multiple => true)
  integer_range_filter(:logins_count, :integer)
  filter(:group_name, :string, :header => "Group") do |value|
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
report = SimpleReport.new(
        :order => "group", 
        :descending => true, 
        :group_id => [1,2], :from_logins_count => 1, 
        :category => "first",
        :order => :group,
        :descending => true
)

report.assets # => Array of User instances: 
              # SELECT * FROM users WHERE users.group_id in (1,2) AND users.logins_count >= 1 AND users.category = 'first' ORDER BY groups.name DESC

report.header # => ["Group", "Name", "Activated"]
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
In common case it is `ActiveRecord::Base` subclass with some generic scopes like in example above:

``` ruby
  scope do
    User.includes(:group)
  end
```

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
* string

[More about filters](https://github.com/bogdan/datagrid/wiki/Filters)


### Columns

Each column is represented by name and code block to calculate the value.
Some formatting options are also available. 
Each column is sortable.

[More about columns](https://github.com/bogdan/datagrid/wiki/Columns) 

### Front end

In order to create form for your report you can use all set of rails built-in tools.

More over Datagrid provides you two additional form helpers:

* datagrid\_label
* datagrid\_filter

The easiest way to create a report form:

(haml for readablity)

``` haml
- form_for @report do |f|
  - @report.filters.each do |filter|
    %div
      = f.datagrid_label filter
      = f.datagrid_filter filter
  = f.submit
```

There is a simple helper set of helpers that allows you display report:

(require will_paginate)

``` haml
- assets = @report.assets.paginate(:page => params[:page])

%div== Total #{assets.total}
= datagrid_table(@report, assets)
= will_paginate assets
```

[More about frontend](https://github.com/bogdan/datagrid/wiki/Frontend)

