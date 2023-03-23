if defined?(MongoMapper)

  class MongoMapperEntry
    include MongoMapper::Document

    key :group_id, Integer
    key :name, String
    key :category, String
    key :disabled, Boolean, default: false
    key :confirmed, Boolean, default: false
    key :shipping_date, Time
    timestamps!

  end

  class MongoMapperGrid
    include ::Datagrid

    scope do
      MongoMapperEntry
    end

    filter :name
    filter(:group_id, range: true, default: [0, 100])
    filter :disabled, :xboolean

    column :name
    column :group_id
    column :disabled

  end
end
