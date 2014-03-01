require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "active_record"
require 'action_view'
require "rails"
require "mongoid"
require "mongo_mapper"
require 'datagrid'
begin
  require 'ruby-debug'
rescue LoadError
end
require 'rspec'
require "logger"

class DatagridTest < Rails::Application

end

if I18n.respond_to?(:enforce_available_locales)
  I18n.enforce_available_locales = true
end

File.open('spec.log', "w").close
TEST_LOGGER = Logger.new('spec.log')


RSpec.configure do |config|


  config.after(:each) do
    #TODO better database truncation
    Group.delete_all
    Entry.delete_all
    MongoidEntry.delete_all
    MongoMapperEntry.delete_all

  end


end



# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/schema.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/support/mongoid.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/support/mongo_mapper.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
