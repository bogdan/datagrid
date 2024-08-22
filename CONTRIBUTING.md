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

# Run tests against Rails 7.2
bundle exec appraisal rails-7.2 rake

# Run tests against Rails 6.1
bundle exec appraisal rails-6.1 rake
```

**Using BUNDLE_GEMFILE**

``` shell
# Run tests against Rails 7.2
BUNDLE_GEMFILE=gemfiles/rails_7.2.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_7.2.gemfile bundle exec rake

# Run tests against Rails 6.1
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_6.1.gemfile bundle exec rake
```
