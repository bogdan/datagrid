# Datagrid

[![Build Status](https://travis-ci.org/bogdan/datagrid.svg?branch=master)](https://travis-ci.org/bogdan/datagrid)

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fbogdan%2Fdatagrid.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fbogdan%2Fdatagrid?ref=badge_shield)

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
* Sequel
* Array (slow but possible)

[Create an issue](https://github.com/bogdan/datagrid/issues/new) if you want more.


### Documentation

* [Readme](/Readme.markdown) - this read-me for basic information
* [Wiki](https://github.com/bogdan/datagrid/wiki) - general reference on how to use the gem
* [Rdoc](https://rdoc.info/github/bogdan/datagrid) - API reference

### Live Demo

[Datagrid DEMO application](http://datagrid.herokuapp.com) is available live!
[Demo source code](https://github.com/bogdan/datagrid-demo).

<img src="http://datagrid.herokuapp.com/datagrid_demo_screenshot.png" style="margin: 7px; border: 1px solid black">

### Example

In order to create a grid:

``` ruby
class UsersGrid

  include Datagrid

  scope do
    User.includes(:group)
  end

  filter(:category, :enum, select: ["first", "second"])
  filter(:disabled, :xboolean)
  filter(:group_id, :integer, multiple: true)
  filter(:logins_count, :integer, range: true)
  filter(:group_name, :string, header: "Group") do |value|
    self.joins(:group).where(:groups => {:name => value})
  end

  column(:name)
  column(:group, order: -> { joins(:group).order(groups: :name) }) do |user|
    user.name
  end
  column(:active, header: "Activated") do |user|
    !user.disabled
  end

end
```

Basic grid api:

``` ruby
report = UsersGrid.new(
  :group_id => [1,2], 
  :logins_count => [1, nil],
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
In common case it is `ActiveRecord::Base` (or any other supported ORM) subclass with some generic scopes like:

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
* float
* date
* datetime
* boolean
* xboolean - the select of "yes", "no" and any
* enum - selection of the given values
* string
* dynamic - build dynamic SQL condition 

[More about filters](https://github.com/bogdan/datagrid/wiki/Filters)


### Columns

Each column is represented by name and code block to calculate the value.

``` ruby
column(:activated, :header => "Active", :order => "activated", :after => :name) do
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
insert  app/assets/stylesheet/application.css
```

### Customize Built-in partials

In order to get a control on datagrid built-in partials run:

``` sh
rake datagrid:copy_partials
```

### Advanced frontend

All advanced frontend things are described in:

[Frontend section on wiki](https://github.com/bogdan/datagrid/wiki/Frontend)

## Questions & Issues

If you have a question of any kind, just make an issue and describe your problem in details.

## Self-Promotion

Like datagrid?

Follow the repository on [GitHub](https://github.com/bogdan/datagrid).

Read [author blog](http://gusiev.com).


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fbogdan%2Fdatagrid.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fbogdan%2Fdatagrid?ref=badge_large)
