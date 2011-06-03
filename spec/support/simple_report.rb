class SimpleReport

  include Datagrid

  filter(:group_id, :integer)
  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :eboolean)
  filter(:confirmed, :boolean)
  filter(:name) do |value|
    self.scoped(:conditions => {:name => value})
  end

  column(:group) do |model|
    Group.find(model.group_id)
  end

  column(:name)

  def scope
    Entry
  end
end
