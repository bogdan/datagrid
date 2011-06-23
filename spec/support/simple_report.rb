

def test_report(attributes = {}, &block)
  klass = Class.new
  klass.class_eval do
    include Datagrid
  end
  klass.class_eval(&block)
  klass.new(attributes)
end

class SimpleReport

  include Datagrid

  scope do
    ::Entry.includes(:group).order("entries.created_at")
  end

  filter(:group_id, :integer, :multiple => true)
  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :eboolean)
  filter(:confirmed, :boolean)

  filter(:name) do |value|
    self.scoped(:conditions => {:name => value})
  end

  column(:group, :order => "groups.name") do
    self.group.name
  end

  column(:name) do |user|
    user.name
  end

  def param_name
    :report
  end

end
