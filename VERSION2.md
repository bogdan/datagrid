# Datagrid Version 2

Datagrid v1 was released Sep 19 2013 - more than 10 years ago.
A lot of new things had happened during this period and it is time.
It caused the library to be designed without support of those technologies
and implementing some of them would cause a breaking change.
And now it is time to indroduce them with Version 2.

List of things introduces:

1. Ruby infinite ranges for range filters.
1. Modern modular CSS classes.
1. HTML5 input types: number, date, datetime-local.
1. HTML5 input [names collision restriction](https://html.spec.whatwg.org/multipage/input.html#input-type-attr-summary)

## Ruby Infinite Ranges

## Modern CSS classes

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
| separator    | datgrid-range-separator             |
| checkboxes   | datagrid-enum-checkboxes            |

A few automatically generated classes were moved from `<input/>` to `<div class="datagrid-filter">`
to make sure they are editable through datagrid partials.

### Example

The difference in layout generation from  v1 to v2

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
filter(:created_at, :datetime, range: true, input_options: {type: 'text'})
filter(:text, :string, input_options: {type: 'textarea'})
```

## Names collision restriction
