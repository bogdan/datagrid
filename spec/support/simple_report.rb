class SimpleReport

  include Datagrid

  filter(:group_id)
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
