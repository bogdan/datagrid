# Datagrid Version 2

Datagrid v1 was released Sep 19 2013 - more than 10 years ago.
A lot of changes in best practices and available technology
had happened during this period.
It caused the library to be designed without support of those technologies
or their implementation to be suboptimal because of backward compatibility.
Version 2 addresses all that evolution.

List of things introduces:

1. Ruby infinite ranges for range filters.
1. Modern modular CSS classes.
1. HTML5 input types: number, date, datetime-local.
1. Use Hash instead of Array for multiparameters attirubtes
   to avoid [input names collision restriction](https://html.spec.whatwg.org/multipage/input.html#input-type-attr-summary)
1. Native Rails Engines:
   while supported, the library was not initially designed for it.
1. HTML5 data attributes
1. Inherit `Datagrid::Base` instead of `include Datagrid`
1. `ApplicationGrid` is recommended base class instead of `BaseGrid`
1. Remove SASS dependency

## Infinite Ranges for range filters

Ruby supports infinite ranges now,
so there is no need to present infinite ranges as Hash or Array.
But it introduces a breaking changes to range filters in Datagrid:

``` ruby
class UsersGrid < Datagrid::Base
  filter(:id, :integer, range: true) do |value, scope|
    # V1 value: [1, nil]
    # V2 value: 1..nil
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
| a.asc        | datagrid-order-control-asc          |
| a.desc       | datagrid-order-control-desc         |
| ordered.asc  | datagrid-order-active-asc           |
| ordered.desc | datagrid-order-active-desc          |
| field        | datagrid-dynamic-field              |
| operation    | datagrid-dynamic-operation          |
| value        | datagrid-dynamic-value              |
| separator    | datagrid-range-separator            |
| checkboxes   | datagrid-enum-checkboxes            |

### Example

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

TODO

``` html
```

## HTML5 input types

Version 1 generated `<input type="text"/>` for every filter type.
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
filter(:salary, :integer, range: true, input_options: {type: 'text'})
```

Additionally, textarea inputs are now supported this way:

``` ruby
# Rendered as <textarea/> tag:
filter(:text, :string, input_options: {type: 'textarea'})
```

## Names collision restriction

HTML5 prohibits multiple inputs to have the same name.
This is contradicts to Rails parameters convention that serializes multiple inputs with same name into array:

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
instead of classes for column names:

### Filters

``` html
<div class="datagrid-filter filter">
  <label for="form_for_grid_category">Category</label>
  <input class="category default_filter" type="text"
     name="form_for_grid[category]" id="form_for_grid_category" />
</div>
```

Version 2:

``` html
<div class="datagrid-filter"
         data-filter="category"
         data-type="string"
>
  <label for="form_for_grid_category">Category</label>
  <input type="text"
      name="form_for_grid[category]" id="form_for_grid_category" />
</div>
```

### Columns

Version 1:

``` html
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
```

Version 2:

``` html
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
```

If you still want to have an HTML class attached to a column use `class` column option:

``` ruby
column(:name, class: 'short-column')
```

``` html
<th class="short-column" data-column="name">Name</th>
...
<td class="short-column" data-column="name">John</td>
```

If you want to change this behavior completely,
modify [built-in partials](https://github.com/bogdan/datagrid/wiki/Frontend#modifying-built-in-partials)

## Inherit Datagrid::Base

`include Datagrid` causes method name space to be clamsy.
Version 2 introduces a difference between the class
that needs to be inherited and high level namespace (just like most gems do):

``` ruby
class ApplicationGrid < Datagrid::Base
end
```

## ApplicationGrid base class

Previously recommended base class `BaseGrid` is incosistent
with Rails naming conventionsa.
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

## All changes in built-in partials

Version 2 built-in partials are trying to expose
as much UI as possible for user modification.

Here is a complete diff for built-in partials between V1 and V2:

TODO update

``` diff
diff --git a/app/views/datagrid/_enum_checkboxes.html.erb b/app/views/datagrid/_enum_checkboxes.html.erb
index 9f48319..f114c17 100644
--- a/app/views/datagrid/_enum_checkboxes.html.erb
+++ b/app/views/datagrid/_enum_checkboxes.html.erb
@@ -4,8 +4,8 @@ You can add indent if whitespace doesn't matter for you
 %>
 <%- elements.each do |value, text, checked| -%>
 <%- id = [form.object_name, filter.name, value].join('_').underscore -%>
-<%= form.label filter.name, options.merge(for: id) do -%>
-<%= form.check_box(filter.name, {multiple: true, id: id, checked: checked, include_hidden: false}, value.to_s, nil) -%>
+<%= form.datagrid_label(filter.name, **options, for: id) do -%>
+<%= form.datagrid_filter_input(filter.name, type: :checkbox, multiple: true, id: id, checked: checked, include_hidden: false, value: value.to_s) -%>
 <%= text -%>
 <%- end -%>
 <%- end -%>
diff --git a/app/views/datagrid/_form.html.erb b/app/views/datagrid/_form.html.erb
index 7e175c1..88a39f9 100644
--- a/app/views/datagrid/_form.html.erb
+++ b/app/views/datagrid/_form.html.erb
@@ -1,12 +1,16 @@
-<%= form_for grid, options do |f| -%>
+<%= form_for grid, html: {class: 'datagrid-form'}, **options do |f| -%>
   <% grid.filters.each do |filter| %>
-    <div class="datagrid-filter filter">
+    <div class="datagrid-filter"
+         data-datagrid-filter="<%= filter.name %>"
+         data-type="<%= filter.type %>"
+         data-datagrid-filter-checkboxes="<%= filter.enum_checkboxes? %>"
+    >
       <%= f.datagrid_label filter %>
       <%= f.datagrid_filter filter %>
     </div>
   <% end %>
   <div class="datagrid-actions">
-    <%= f.submit I18n.t("datagrid.form.search").html_safe, class: "datagrid-submit" %>
-    <%= link_to I18n.t('datagrid.form.reset').html_safe, url_for(grid.to_param => {}), class: "datagrid-reset" %>
+    <%= f.submit I18n.t("datagrid.form.search"), class: "datagrid-submit" %>
+    <%= link_to I18n.t('datagrid.form.reset'), url_for(grid.to_param => {}), class: "datagrid-reset" %>
   </div>
 <% end -%>
diff --git a/app/views/datagrid/_head.html.erb b/app/views/datagrid/_head.html.erb
index e939128..affccf4 100644
--- a/app/views/datagrid/_head.html.erb
+++ b/app/views/datagrid/_head.html.erb
@@ -1,6 +1,6 @@
 <tr>
   <% grid.html_columns(*options[:columns]).each do |column| %>
-    <th class="<%= datagrid_column_classes(grid, column) %>">
+    <th class="<%= datagrid_column_classes(grid, column) %>" data-datagrid-column="<%= column.name %>">
       <%= column.header %>
       <%= datagrid_order_for(grid, column, options) if column.supports_order? && options[:order]%>
     </th>
diff --git a/app/views/datagrid/_order_for.html.erb b/app/views/datagrid/_order_for.html.erb
index 1545a8e..1c33c37 100644
--- a/app/views/datagrid/_order_for.html.erb
+++ b/app/views/datagrid/_order_for.html.erb
@@ -1,10 +1,10 @@
-<div class="order">
+<div class="datagrid-order">
   <%= link_to(
-      I18n.t("datagrid.table.order.asc").html_safe,
+      I18n.t("datagrid.table.order.asc"),
       datagrid_order_path(grid, column, false),
-      class: "asc") %>
+      class: "datagrid-order-control-asc") %>
   <%= link_to(
-      I18n.t("datagrid.table.order.desc").html_safe,
+      I18n.t("datagrid.table.order.desc"),
       datagrid_order_path(grid, column, true),
-      class: "desc") %>
+      class: "datagrid-order-control-desc") %>
 </div>
diff --git a/app/views/datagrid/_range_filter.html.erb b/app/views/datagrid/_range_filter.html.erb
index 7a8a123..1b90dc8 100644
--- a/app/views/datagrid/_range_filter.html.erb
+++ b/app/views/datagrid/_range_filter.html.erb
@@ -1,3 +1,3 @@
 <%= form.datagrid_filter_input(filter, **from_options) %>
-<span class="separator <%= filter.type %>"><%= I18n.t('datagrid.filters.range.separator') %></span>
+<span class="datagrid-range-separator"><%= I18n.t('datagrid.filters.range.separator') %></span>
 <%= form.datagrid_filter_input(filter, **to_options) %>
diff --git a/app/views/datagrid/_row.html.erb b/app/views/datagrid/_row.html.erb
index f54d21c..b431ab7 100644
--- a/app/views/datagrid/_row.html.erb
+++ b/app/views/datagrid/_row.html.erb
@@ -1,5 +1,5 @@
 <tr>
   <% grid.html_columns(*options[:columns]).each do |column| %>
-    <td class="<%= datagrid_column_classes(grid, column) %>"><%= datagrid_value(grid, column, asset) %></td>
+    <td class="<%= datagrid_column_classes(grid, column) %>" data-datagrid-column="<%= column.name %>"><%= datagrid_value(grid, column, asset) %></td>
   <% end %>
 </tr>
diff --git a/app/views/datagrid/_table.html.erb b/app/views/datagrid/_table.html.erb
index 8708c05..0b5ff24 100644
--- a/app/views/datagrid/_table.html.erb
+++ b/app/views/datagrid/_table.html.erb
@@ -5,7 +5,7 @@ Local variables:
 * options - passed options Hash
 %>
 <% if grid.html_columns(*options[:columns]).any? %>
-  <%= content_tag :table, options[:html] do %>
+  <%= content_tag :table, class: 'datagrid-table', **options.fetch(:html, {}) do %>
     <thead>
       <%= datagrid_header(grid, options) %>
     </thead>
@@ -13,10 +13,10 @@ Local variables:
       <% if assets.any? %>
         <%= datagrid_rows(grid, assets, **options) %>
       <% else %>
-        <tr><td class="noresults" colspan="100%"><%= I18n.t('datagrid.no_results').html_safe %></td></tr>
+        <tr><td class="datagrid-no-results" colspan="100%"><%= I18n.t('datagrid.no_results') %></td></tr>
       <% end %>
     </tbody>
   <% end %>
 <% else -%>
-  <%= I18n.t("datagrid.table.no_columns").html_safe %>
+  <%= I18n.t("datagrid.table.no_columns") %>
 <% end %>
```
