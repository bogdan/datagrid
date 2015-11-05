require "sequel"


DB = Sequel.sqlite # memory database

DB.create_table :sequel_entries do
  primary_key :id

  Integer :group_id
  String :name
  String :category
  Boolean :disabled
  Boolean :confirmed
  Time :shipping_date
  Time :created_at
end

class SequelEntry < Sequel::Model

end


class SequelGrid
  include ::Datagrid

  scope do
    SequelEntry
  end

  filter :name
  integer_range_filters(:group_id, {:default => 0}, {:default => 100})
  filter :disabled, :xboolean

  column :name
  column :group_id
  column :disabled

end

