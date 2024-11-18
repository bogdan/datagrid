# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  gem "activerecord"
  gem "appraisal"
  gem "bump"
  gem "csv" # removed from standard library in Ruby 3.4
  gem "debug"
  gem "nokogiri" # used to test html output
  gem "pry-byebug"
  gem "rails-dom-testing", "~> 2.2"
  gem "rspec"
  gem "rubocop", "~> 1.68"
  gem "rubocop-yard", "~> 0.9.3", require: false
  gem "sequel"
  gem "sqlite3", "~> 1.7.0"

  group :mongo do
    gem "bson"
    gem "mongoid", "~> 9.0"
  end
end
