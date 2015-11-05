

def test_report(attributes = {}, &block)
  klass = test_report_class(&block)
  klass.new(attributes)
end

def test_report_class(&block)
  Class.new.tap do |klass|
    klass.class_eval do
      include Datagrid
      def self.name
        "TestGrid"
      end
    end
    if block
      klass.class_eval(&block)
    end
  end
end

class SimpleReport

  include Datagrid

  scope do
    ::Entry.includes(:group).order("entries.created_at")
  end

  filter(:group_id, :integer, :multiple => true)
  filter(:category, :enum, :select => ["first", "second"])
  filter(:disabled, :xboolean)
  filter(:confirmed, :boolean)

  filter(:name) do |value|
    self.where(:name => value)
  end

  column(:group, :order => "groups.name") do
    self.group.name
  end

  column(:name) do |user|
    user.name
  end

  column(:actions, :html => true) do |model|
    render :partial => "actions", :locals => {:model => model}
  end

  column(:pet, :html => lambda {|data| content_tag :em, data}) do
    self.pet.try(:upcase)
  end

  column(:shipping_date, :before => :group)

  column(:access_level, :html => lambda {|data| content_tag :h1, data}, :after => :actions)

  def param_name
    :report
  end

end

