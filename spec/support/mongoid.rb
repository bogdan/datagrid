require "rubygems"

#Mongoid.logger = TEST_LOGGER #TODO: understand why still output to STDOUT


class MongoidEntry

  include Mongoid::Document
  include Mongoid::Timestamps

  field :group_id, type: Integer
  field :name, type: String
  field :category, type: String
  field :disabled, default: false, type: Boolean
  field :confirmed, default: false, type: Boolean
  field :shipping_date, type: Time

end

class MongoidGrid
  include ::Datagrid

  scope do
    MongoidEntry
  end

  filter :name
  filter(:group_id, :integer, range: true, default: 0..100)
  filter :disabled, :xboolean

  column :name
  column :group_id
  column :disabled

end

