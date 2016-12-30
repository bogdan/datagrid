source "https://rubygems.org"

gem "rails", ">= 4.0"

group :development do

  gem "bundler"
  if RUBY_VERSION >= "2.3"
    gem "jeweler", ">= 2.1.2", platform: [:ruby_23, :ruby_24]
  end


  #gem "json", ">= 1.9"
  gem "pry-byebug", :platform => [:ruby_20, :ruby_21, :ruby_22, :ruby_23] & Bundler::Dsl::VALID_PLATFORMS

  gem "rspec", ">= 3"
  gem "nokogiri" # used to test html output

  gem "sqlite3"
  gem "sequel"

  group :mongo do
    gem "mongoid"
    #gem "mongo_mapper", "~> 0.13.0"
    gem "bson"
    gem "bson_ext"
  end

end
