source "https://rubygems.org"

gemspec

group :development do
  gem "bump"

  gem "pry-byebug"

  gem "rspec"
  gem "nokogiri" # used to test html output

  gem "sqlite3", platform: :mri
  gem "sequel"
  gem "activerecord"

  group :mongo do
    gem "mongoid"
    gem "bson"
  end
end
