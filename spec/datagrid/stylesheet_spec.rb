# frozen_string_literal: true

require "spec_helper"

describe "Datagrid stylesheet" do
  it "works correctly" do
    if Rails.application.assets.respond_to?(:find_asset)
      asset = Rails.application.assets.find_asset("datagrid")
      asset
    end
  end
end
