

def test_report(attributes = {}, &block)
  klass = Class.new
  klass.class_eval do
    include Datagrid
  end
  if block
    klass.class_eval(&block)
  end
  klass.new(attributes)
end

class SimpleReport

  include Datagrid

  scope do
    ::Entry.includes(:group).order("entries.created_at")
  end

  filter(:group_id, :integer, :multiple => true)
  filter(:category, :enum, :select => ["first", "second"])
  filter(:category_without_include_blank, :enum, :select => ["first", "second"], :include_blank => false)
  filter(:category_with_prompt, :enum, :select => ["first", "second"], :prompt => "My Prompt")
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
