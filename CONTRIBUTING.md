# Contributing to Datagrid

## Issues

Please use GitHub issues for bug reports and feature suggestions.

## Development

### Testing

Tests can be run against different versions of Rails:

**Using appraisals (recommended)**

``` shell
# Install the dependencies for each appraisal
bundle install
bundle exec appraisal install

# Run tests against Rails 8.1
bundle exec appraisal rails-8.1 rake

# Run tests against Rails 7.0
bundle exec appraisal rails-7.0 rake
```

**Using BUNDLE_GEMFILE**

``` shell
# Run tests against Rails 8.1
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_8.1.gemfile bundle exec rake

# Run tests against Rails 7.0
BUNDLE_GEMFILE=gemfiles/rails_7.0.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_7.0.gemfile bundle exec rake
```
