# frozen_string_literal: true

appraise "rails-7.0" do
  group :development do
    gem "rails", "~> 7.0.0"
    gem "sqlite3", "~> 1.7.0"
  end
end

appraise "rails-7.1" do
  group :development do
    gem "rails", "~> 7.1.0"
    gem "sqlite3", "~> 1.7.0"
  end
end

appraise "rails-7.2" do
  group :development do
    gem "rails", "~> 7.2.0"
    gem "sqlite3", "~> 2.0.0"
    group :mongo do
      gem "mongoid", github: "mongodb/mongoid"
    end
  end
end

appraise "rails-8.0" do
  group :development do
    gem "rails", "~> 8.0.0"
    gem "sqlite3", "~> 2.1.0"
    group :mongo do
      gem "mongoid", github: "mongodb/mongoid"
    end
  end
end
