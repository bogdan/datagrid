require "rubygems"
require 'mongo_mapper'

MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
MongoMapper.database = "datagrid_mongo_mapper"

class MongoMapperEntry
  include MongoMapper::Document

  key :group_id, Integer
  key :name, String
  key :category, String
  key :disabled, Boolean, :default => false
  key :confirmed, Boolean, :default => false
  key :shipping_date, DateTime
  timestamps!

end

class MongoMapperGrid
  include ::Datagrid

  scope do
    MongoMapperEntry
  end

  filter :name
  integer_range_filters(:group_id, {:default => 0}, {:default => 100})
  filter :disabled, :eboolean

  column :name
  column :group_id
  column :disabled

end

