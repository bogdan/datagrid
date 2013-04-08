# Datagrid

Ruby library that helps you to build and represent table-like data with:

* Customizable filtering
* Columns
* Sort order
* Localization
* Export to CSV

### ORM Support

* ActiveRecord
* Mongoid
* MongoMapper

[Create an issue](https://github.com/bogdan/datagrid/issues/new) if you want more.

### Live Demo

[Datagrid DEMO application](http://datagrid.heroku.com) is available live!
[Demo source code](https://github.com/bogdan/datagrid-demo).

<img src="http://datagrid.heroku.com/datagrid_demo_screenshot.png" style="margin: 7px; border: 1px solid black">

### Example

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
  filter(:logins_count, :integer, :range => true)
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
        :group_id => [1,2], :from_logins_count => 1, 
        :category => "first",
        :order => :group,
        :descending => true
)

report.assets # => Array of User instances: 
              # SELECT * FROM users WHERE users.group_id in (1,2) AND users.logins_count >= 1 AND users.category = 'first' ORDER BY groups.name DESC

report.header # => ["Name", "Group", "Activated"]
report.rows   # => [
              #      ["Steve", "Spammers", false],
              #      [ "John", "Spoilers", false],
              #      ["Berry", "Good people", true]
              #    ]
report.data   # => [ header, *rows]

report.to_csv # => Yes, it is
```

### Grid DSL

In order to create a report, you need to define:

* scope of objects to look through
* filters that will be used to filter data
* columns that should be displayed and sortable (if possible)


### Scope

Default scope of objects to filter and display.
In common case it is `ActiveRecord::Base` (or any other supported ORM) subclass with some generic scopes like in example above:

``` ruby
  scope do
    User.includes(:group)
  end
```

[More about scope](https://github.com/bogdan/datagrid/wiki/Scope)

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

``` ruby
column(:activated, :header => "Active", :order => "activated") do
  self.activated?
end
```

Some formatting options are also available. 
Each column is sortable.

[More about columns](https://github.com/bogdan/datagrid/wiki/Columns) 

### Front end

### Using Generator

Datagrid has a builtin generator:

```
rails g datagrid:scaffold skills
```

That gives you some code to play with out of the box:

```
create  app/grids/skills_grid.rb
create  app/controllers/skills_controller.rb
create  app/views/skills/index.html.erb
route  resources :skills
```

### Manually

If you want to be a true ninja you can build everything from scratch on your own.

In order to create form for your report you can use all set of rails built-in tools.
More over Datagrid provides you two additional form helpers:

* datagrid\_label
* datagrid\_filter


The easiest way to create a report form (haml for readablity):

``` haml
# Method `GET` is recommended for all report forms by default.
- form_for @report, :html => {:method => :get} do |f|
  - @report.filters.each do |filter|
    %div
      = f.datagrid_label filter
      = f.datagrid_filter filter
  = f.submit
```

Your controller:

``` ruby
map.resources :simple_reports, :only => [:index]

class SimpleReportsController < ApplicationController
  def index
    @report = SimpleReport.new(params[:simple_report])
  end
end
```

There is a simple helper set of helpers that allows you display report:
(require any pagination gem, will\_paginate is used as an example)

``` haml
- assets = @report.assets.paginate(:page => params[:page])

%div== Total #{assets.total_entries}
= datagrid_table(@report, assets)
= will_paginate assets
```

If you need a custom interface for your report you should probably build it yourself with datagrid helpers.

[More about frontend](https://github.com/bogdan/datagrid/wiki/Frontend)

## Self-Promotion

Like datagrid? 

Follow the repository on [GitHub](https://github.com/bogdan/datagrid). 

Read [author blog](http://gusiev.com).
