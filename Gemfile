source "https://rubygems.org"

gem "rails", ">= 3.2.22.2"

group :development do

  gem "bundler"
  gem "jeweler"


  gem "debugger", :platform => :ruby_19
  gem "byebug", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23] & Bundler::Dsl::VALID_PLATFORMS

  gem "rspec", ">= 3"
  gem "nokogiri" # used to test html output

  gem "sqlite3"
  gem "sequel"

  group :mongo do
    gem "mongoid", "3.1.7"
    gem "mongo_mapper", "~> 0.13.0"
    gem "bson"
    gem "bson_ext"
  end

end
