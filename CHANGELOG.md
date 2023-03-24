## master

* Fixed scope wrapping to be universal
* Deprecated `integer_range_filters` and `date_range_filters`. Use `filter(name, type, range: true)` instead.
* Add `original_scope` method that returns scope as it was defined without any wrapping [#313](https://github.com/bogdan/datagrid/pull/313)

## 1.7.0

* Depend on `railties` instead of `rails` to prevent loading of unnecessary frameworks
* Bugfix `File.exist?` usage for ruby 3.0 [#307](https://github.com/bogdan/datagrid/issues/307)
* Drop support of old Ruby versions (< 2.7)
* Drop support of old Rails versions (< 6.0)

## 1.6.3

* Fix usage of options spread operator for Ruby 3.0 [#296](https://github.com/bogdan/datagrid/issues/296)

## 1.6.2

* Add `input_options` and `label_options` to `filter` method [#294](https://github.com/bogdan/datagrid/issues/294)
* Fix `<option>` tag rendering for Rails 6.0

## 1.6.1 and before

Changes are not tracked
