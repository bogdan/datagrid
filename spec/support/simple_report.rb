# frozen_string_literal: true

def test_grid(attributes = {}, &block)
  klass = test_grid_class(&block)
  klass.new(attributes)
end

def test_grid_class(&block)
  Class.new(Datagrid::Base).tap do |klass|
    klass.class_eval do
      def self.name
        "TestGrid"
      end
    end
    if block
      klass.class_eval(&block)
    else
      klass.scope { Entry }
    end
  end
end

def test_grid_column(name, query = nil, **options, &block)
  test_grid do
    scope { Entry }
    column(name, query, **options, &block)
  end
end

def test_grid_filter(name, type = :default, **options, &block)
  test_grid do
    scope { Entry }
    filter(name, type, **options, &block)
  end
end

class SimpleReport < Datagrid::Base
  scope do
    ::Entry.includes(:group).order("entries.created_at")
  end

  filter(:group_id, :integer, multiple: true)
  filter(:category, :enum, select: %w[first second])
  filter(:disabled, :xboolean)
  filter(:confirmed, :boolean)

  filter(:name) do |value|
    where(name: value)
  end

  column(:group, order: "groups.name") do
    group.name
  end

  column(:name, &:name)

  column(:actions, html: true) do |model|
    render partial: "/actions", locals: { model: model }
  end

  column(:pet, html: ->(data) { content_tag :em, data }) do
    pet&.upcase
  end

  column(:shipping_date, before: :group)

  column(:access_level, html: ->(data) { content_tag :h1, data }, after: :actions)

  def param_name
    :report
  end
end
