# Datagrid Version 2

Datagrid v1 was released on Sep 19 2013 - more than 10 years ago.
A lot of changes in best practices and available technology
had happened during this period.
It caused the library to be designed without support of those technologies
or their implementation to be suboptimal because of backward compatibility.
Version 2 addresses all that evolution.

List of things introduces:

## API changes

1. Ruby endless ranges for range filters.
1. Use Hash instead of Array for multiparameter attributes.
1. Remove `column[url]` option.
1. Inherit `Datagrid::Base` instead of `include Datagrid`.
1. `ApplicationGrid` is recommended base class instead of `BaseGrid`.

## Frontend Changes

1. Use `form_with` instead of `form_for`.
1. Deprecated `datagrid_order_for`
1. Modern modular CSS classes.
1. HTML5 input types: number, date, datetime-local.
1. Native Rails Engines:
   * while supported, the library was not initially designed for it.
1. HTML5 data attributes
1. Consistent `label[for]` and `input[id]` for range filters.
1. Introduced `datagrid.filters.range.separator` localization
1. Remove SASS dependency
1. Replace `rake datagrid:copy_partials` with `rails g datagrid:views`

## Remove column[url] option

`column[url]` option was introduced before flexible data/html output layer for columns was established. Here is how the deprecated option can be migrated to modern setup:

Version 1:

``` ruby
column(:user, url: -> (user) => { user_profile_path(user) }) do
  user.name
end
```

Version 2:

``` ruby
column(:user) do |user|
  format(user.name) do |value|
    link_to value, user_profile_path(user)
  end
end
```

All deprecated columns can be found [with a script](./find_deprecated_url_option.rb)

## Use form\_with

Rails [deprecates form\_for in favor of form\_with](https://guides.rubyonrails.org/form_helpers.html#using-form-tag-and-form-for).

`datagrid_form_for` is now deprecated if favor of `datagrid_form_with`.

TODO: update the wiki

``` ruby
# V1
datagrid_form_for(@users_grid, url: users_path)
# V2
datagrid_form_with(model: @users_grid, url: users_path)
```

Version 2 built-in view `datagrid/form` uses `form_with` no matter of the with helper is used.
Beware of that.

[Grep all deprecations](./deprecations.sh).

## Deprecated datagrid\_order\_for

`datagrid_order_for` helper serves no purpose and should not be used directly.
The recommended way is to include your ordering code directly into `datagrid/head` partial.
See default [head partial](../app/views/datagrid/_head.html.erb) for example.

You can implement `datagrid_order_for` in `ApplicationHelper` 
and copy [datagrid/order\_for](../app/views/datagrid/_order_for.html.erb) into your project if you consider it useful:

``` ruby
module ApplicationHelper
  def datagrid_order_for(grid, column)
    render(partial: "datagrid/order_for", locals: { grid: grid, column: column })
  end
end
```

[Grep all deprecations](./deprecations.sh).

## Inherit Datagrid::Base

`include Datagrid` causes method name space to be clamsy.
Version 2 introduces a difference between the class
that needs to be inherited and high level namespace (just like most gems do):

``` ruby
class ApplicationGrid < Datagrid::Base
end
```

[Grep all deprecations](./deprecations.sh).

## Endless ranges for range filters

Ruby supports endless ranges now,
so there is no need to present endless ranges as Hash or Array.
But it introduces a breaking changes to range filters in Datagrid:

``` ruby
class UsersGrid < Datagrid::Base
  filter(:id, :integer, range: true) do |value, scope|
    # V1 value is  [1, nil]
    # V2 value is 1..nil
    scope.where(id: value)
  end
end

grid = UsersGrid.new
grid.id = [1, nil]
grid.id # V1: [1, nil]
        # V2: (1..nil)
```

Version 2 makes an effort to make the transition as smooth as possible to you:

* Old Array format will be converted to new Range format
* Serialization/Deserialization of Range is help correctly

``` ruby
grid.id = 1..5
grid.id # => 1..5

grid.id = "1..5"
grid.id # => 1..5

grid.id = [nil, 5]
grid.id # => ..5

grid.id = nil..nil
grid id # => nil

grid.id = 3..7
# Simulate serialization/deserialization when interacting with
# jobs queue or database storage
grid = UsersGrid.new(ActiveSupport::JSON.load(grid.attributes.to_json))
grid.id # => 3..7
```

This very likely breaks all `range: true` filters with custom block passed.
All such filters can be seen with this script (works only for V2):

[Search all broken range filters](./find_broken_range_filters.rb)

## Modern CSS classes naming conventions

Built-in generated CSS classes renamed to match modern CSS naming conventions
and avoid collisions with other libraries:

| Old Name     | New Name                            |
|--------------|-------------------------------------|
| filter       | datagrid-filter                     |
| from         | datagrid-input-from                 |
| to           | datagrid-input-to                   |
| noresults    | datagrid-no-results                 |
| datagrid     | datagrid-table                      |
| order        | datagrid-order                      |
| asc          | datagrid-order-control-asc          |
| desc         | datagrid-order-control-desc         |
| ordered.asc  | datagrid-order-active-asc           |
| ordered.desc | datagrid-order-active-desc          |
| field        | datagrid-dynamic-field              |
| operation    | datagrid-dynamic-operation          |
| value        | datagrid-dynamic-value              |
| separator    | datagrid-range-separator            |
| checkboxes   | datagrid-enum-checkboxes            |

All classes are now explicitly assinged inside datagrid partials.
[Modify built-in partials](https://github.com/bogdan/datagrid/wiki/Frontend#modifying-built-in-partials)
if you want to change them.

Diff for [built-in partials between V1 and V2](./views.diff)
See [a new built-in CSS file](../app/assets/datagrid.css).

### Form layout difference

The difference in layout generation from v1 to v2.

``` ruby
datagrid_form_for(@grid)
```

Version 1 layout:

``` html
<form class="datagrid-form partial_default_grid" id="new_g"
    action="/users" accept-charset="UTF-8" method="get">
  <input name="utf8" type="hidden" value="✓" autocomplete="off" />

  <div class="datagrid-filter filter">
    <label for="g_id">Id</label>
    <input class="id integer_filter from" multiple type="text" name="g[id][]" />
    <span class="separator integer"> - </span>
    <input class="id integer_filter to" multiple type="text" name="g[id][]" />
  </div>

  <div class="datagrid-filter filter">
    <label for="g_group_id">Group</label>
    <label class="group_id enum_filter checkboxes" for="g_group_id_1">
      <input id="g_group_id_1" type="checkbox" value="1" name="g[group_id][]" />1
    </label>
    <label class="group_id enum_filter checkboxes" for="g_group_id_2">
      <input id="g_group_id_2" type="checkbox" value="2" name="g[group_id][]" />2
    </label>
  </div>

  <div class="datagrid-actions">
    <input type="submit" name="commit" value="Search"
        class="datagrid-submit" data-disable-with="Search" />
    <a class="datagrid-reset" href="/location">Reset</a>
  </div>
</form>
```

Version 2 layout:

``` html
<form class="datagrid-form" action="/users" accept-charset="UTF-8" method="get">
  <div class="datagrid-filter" data-filter="id" data-type="integer">
    <label for="g_id">Id</label>
    <input step="1" class="datagrid-range-from" name="g[id][from]" type="number" id="g_id" />
    <span class="datagrid-range-separator"> - </span>
    <input step="1" class="datagrid-range-to" name="g[id][to]" type="number" />
  </div>

  <div class="datagrid-filter" data-filter="group_id" data-type="enum">
    <label>Group</label>
    <div class="datagrid-enum-checkboxes">
      <label for="g_group_id_1" class="datagrid-enum-checkbox-label">
        <input id="g_group_id_1" value="1" type="checkbox" name="g[group_id][]" />1
      </label>
      <label for="g_group_id_2" class="datagrid-enum-checkbox-label">
        <input id="g_group_id_2" value="2" type="checkbox" name="g[group_id][]" />2
      </label>
    </div>
  </div>

  <div class="datagrid-actions">
    <input type="submit" name="commit" value="Search" class="datagrid-submit" data-disable-with="Search" />
    <a class="datagrid-reset" href="/location">Reset</a>
  </div>
</form>
```

## HTML5 input types

Version 1 generated `<input type="text"/>` for most filter types.
Version 2 uses the appropriate input type for each filter type:

| Type       | HTML Input Element                         |
|------------|--------------------------------------------|
| string     | `<input type="text"/>`                     |
| boolean    | `<input type="checkbox"/>`                 |
| date       | `<input type="date"/>`                     |
| datetime   | `<input type="datetime-local"/>`           |
| enum       | `<select>`                                 |
| xboolean   | `<select>`                                 |
| float      | `<input type="number" step="any"/>`        |
| integer    | `<input type="number" step="1"/>`          |

The default behavior can be changed back by using `input_options`:

``` ruby
filter(:created_at, :date, range: true, input_options: {type: 'text'})
filter(:salary, :integer, range: true, input_options: {type: 'text', step: nil})
```

You can disable HTML5 inputs with:

``` ruby
class ApplicationGrid < Datagrid::Base
  def self.filter(name, type = :default, input_options: {}, **options)
    if [:date, :datetime, :float, :integer].include?(type)
      input_options[:type] ||= 'text'
    end

    super(name, type, input_options:, **options)
  end
end
```

Additionally, textarea inputs are now supported this way:

``` ruby
# Rendered as <textarea/> tag:
filter(:text, :string, input_options: {type: 'textarea'})
```

## Prefer Hash instead of Array for multiparameter filter types

Rails multiple input had been a problem [#325](https://github.com/bogdan/datagrid/issues/325).

``` html
Date From:
<input type="number" name="grid[members_count][]" value="1"/>
Date To:
<input type="number" name="grid[members_count][]" value="5"/>
```

Serialized to:

``` ruby
{grid: {members_count: ['1', '5']}}
```

V1 had used this convention for `range: true` and `dynamic` filter type.
Now, they are using the following convention instead:

``` html
Date From:
<input type="number" name="grid[members_count][from]" value="1"/>
Date To:
<input type="number" name="grid[members_count][to]" value="5"/>
```

`Grid#members_count` will automatically typecast a hash
into appropriate `Range` on assignment:

``` ruby
grid.members_count = {from: 1, to: 5}
grid.members_count # => 1..5
```

The old convention would still work
to ensure smooth transition to new version:

``` ruby
grid.members_count = [3, 7]
grid.members_count # => 3..7
```

However, the `f.datagrid_filter :members_count`
will always generate from/to inputs instead:

``` html
<input value="3" type="number" step="1" name="grid[members_count][from]"/>
<span class="datagrid-range-separator"> - </span>
<input value="7" type="number" step="1" name="grid[members_count][to]"/>
```

## HTML5 data attributes

It is more semantic and collision proof to use `data-*` attributes
instead of classes for meta information from backend.
Therefor built-in partials now generate data attributes by default
instead of classes for column names.

* Filter name `input[class]` implemented as `.datagrid-filter[data-filter]`.
* Filter type `input[class]` implemented as `.datagrid-filter[data-type]`.
* Grid class `table[class]` removed due to:
  * security concerns from some users
  * breaking CSS classes naming convention
* Column name `th[class], td[class]` implemented as `td[data-column], th[data-column]`.

Note that the behavior change can be reverted by 
[updating built-in partials](https://github.com/bogdan/datagrid/wiki/Frontend#modifying-built-in-partials).
Version 2 makes it as easy as possible to override the defaults of the UI.

### Filters

Version 1:

``` html
<div class="datagrid-filter filter">
  <label for="form_for_grid_category">Category</label>
  <input class="category default_filter" type="text"
     name="form_for_grid[category]" id="form_for_grid_category" />
</div>
```

Version 2:

``` html
<div class="datagrid-filter" data-filter="category" data-type="string">
  <label for="form_for_grid_category">Category</label>
  <input type="text"
      name="form_for_grid[category]" id="form_for_grid_category" />
</div>
```

Diff for [built-in views between V1 and V2](./views.diff)

### Columns

Version 1:

``` html
<table class="datagrid users_grid">
    <tr>
        <th class="name">Name</th>
        <th class="category">Category</th>
    </tr>
    <tr>
        <td class="name">John</th>
        <td class="category">Worker</th>
    </tr>
    <tr>
        <td class="name">Mike</th>
        <td class="category">Manager</th>
    </tr>
</table>
```

Version 2:

``` html
<table class="datagrid-table">
    <tr>
        <th data-column="name">Name</th>
        <th data-column="category">Category</th>
    </tr>
    <tr>
        <td data-column="name">John</th>
        <td data-column="category">Worker</th>
    </tr>
    <tr>
        <td data-column="name">Mike</th>
        <td data-column="category">Manager</th>
    </tr>
</table>
```

If you still want to have an HTML class attached to a column use `class` column option:

``` ruby
column(:name, class: 'short-column')
```

Renders:

``` html
<th class="short-column" data-column="name">Name</th>
...
<td class="short-column" data-column="name">John</td>
```

[Modify built-in views](https://github.com/bogdan/datagrid/wiki/Frontend#modifying-built-in-partials)
if you want to change this behavior completely.

## id attribute for range filter inputs

[W3 validator](https://validator.w3.org/) complains when 
a `label[for]` attribute doesn't correspond to any `input[id]` in the same form.
Version 1 generated no id attribute for range filter inputs by default which resulted in a warning:

``` html
<label for="musics_grid_year">Year</label>
<input class="year integer_fiilter from" multiple name="musics_grid[year][]" type="text">
<span class="separator integer"> - </span>
<input class="year integer_filter to" multiple name="musics_grid[year][]" type="text">
```

Version 2 generates id attribute only for the first input, so that a click on label focuses the first input:

``` html
<label for="musics_grid_year">Year</label>
<input id="musics_grid_year" step="1" class="datagrid-range-from" name="musics_grid[year][from]" type="number">
<span class="datagrid-range-separator"> - </span>
<input step="1" class="datagrid-range-to" name="musics_grid[year][to]" type="number">
```

The behavior can be changed by modifying 
[built-in view](https://github.com/bogdan/datagrid/blob/version-2/app/views/datagrid/_range_filter.html.erb#L3).

## ApplicationGrid base class

Previously recommended base class `BaseGrid` is incosistent
with Rails naming conventions.
It was renamed to `ApplicationGrid` instead:

``` ruby
# app/grids/application_grid.rb
class ApplicationGrid < Datagrid::Base
  def self.timestamp_column(name, *args, &block)
    column(name, *args) do |model|
      value = block ? block.call(model) : model.public_send(name)
      value&.strftime("%Y-%m-%d")
    end
  end
end

# app/grids/users_grid.rb
class UsersGrid < ApplicationGrid
  scope { User }

  column(:name)
  timestamp_column(:created_at)
end
```

## Introduced range filter separator localization

A separator symbol between range filter inputs is now a part of localizations to avoid hard coding.
Add `datagrid.filters.range.separator` to your localization file.

[See related view](https://github.com/bogdan/datagrid/blob/version-2/app/views/datagrid/_range_filter.html.erb#L2)


## Remove SASS dependency

SASS is no longer a default choice when starting a Ruby on Rails project.
Version 2 makes it more flexible by avoiding the dependency on any particular CSS framework.

See [a new built-in CSS file](../app/assets/stylesheets/datagrid.css).
