# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Filters::FloatFilter do
  it "supports float values" do
    g1 = Group.create!(rating: 1.5)
    g2 = Group.create!(rating: 1.6)
    report = test_grid(rating: 1.5) do
      scope { Group }
      filter(:rating, :float)
    end
    expect(report.assets).to include(g1)
    expect(report.assets).not_to include(g2)
  end
end
