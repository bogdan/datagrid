
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true

ActiveRecord::Base.logger = TEST_LOGGER




ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(:version => 1) do

  create_table :entries do |t|
    t.integer :group_id
    t.string :name
    t.string :category
    t.string :access_level
    t.string :pet
    t.boolean :disabled, :null => false, :default => false
    t.boolean :confirmed, :null => false, :default => false
    t.date :shipping_date
    t.timestamps
  end

  create_table :groups do |t|
    t.string :name
    t.float :rating 
    t.timestamps
  end

  class ::Entry < ActiveRecord::Base
    belongs_to :group
  end
  class ::Group < ActiveRecord::Base
    has_many :entries
  end
end
