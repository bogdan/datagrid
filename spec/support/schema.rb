require "logger"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true

File.open('spec.log', "w").close
ActiveRecord::Base.logger = Logger.new('spec.log')



WillPaginate.enable

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define(:version => 1) do

  create_table :entries do |t|
    t.integer :group_id
    t.string :name
    t.string :category
    t.boolean :disabled, :null => false, :default => nil
    t.boolean :confirmed, :null => false, :default => nil
  end

  create_table :groups do |t|
    t.string :name
  end

  class ::Entry < ActiveRecord::Base
    belongs_to :group
  end
  class ::Group < ActiveRecord::Base
  end
end
