class SimpleReport

  include Datagrid


  scope do
    ::Entry.includes(:group)
  end

  filter(:group_id, :integer)
  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :eboolean)
  filter(:confirmed, :boolean)
  filter(:name) do |value|
    self.scoped(:conditions => {:name => value})
  end

  column(:group, :order => "groups.name") do |model|
    group.name
  end

  column(:name)

end
