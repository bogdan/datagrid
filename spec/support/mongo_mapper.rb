require "rubygems"

class MongoMapperEntry
  include MongoMapper::Document

  key :group_id, Integer
  key :name, String
  key :category, String
  key :disabled, Boolean, :default => false
  key :confirmed, Boolean, :default => false
  key :shipping_date, Time
  timestamps!

end

class MongoMapperGrid
  include ::Datagrid

  scope do
    MongoMapperEntry
  end

  filter :name
  integer_range_filters(:group_id, {:default => 0}, {:default => 100})
  filter :disabled, :xboolean

  column :name
  column :group_id
  column :disabled

end

