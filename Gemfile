source "https://rubygems.org"

gemspec

group :development do
  rails_version = ENV['TEST_RAILS_VERSION']
  gem "rails", "~> #{rails_version}" if rails_version
  gem "bump"

  gem "pry-byebug"

  gem "rspec"
  gem "nokogiri" # used to test html output

  gem "sqlite3", '~> 1.4.0'
  gem "sequel"
  gem "activerecord"

  group :mongo do
    gem "mongoid"
    gem "bson"
  end
end
