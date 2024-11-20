# frozen_string_literal: true

require "spec_helper"

describe Datagrid::ActiveModel do
  class ActiveReport
    include Datagrid::ActiveModel
  end

  module Grid
    class ActiveReport
      include Datagrid::ActiveModel
    end
  end

  describe ".model_name" do
    it "is generate from class name" do
      expect(ActiveReport.model_name).to eq("ActiveReport")
    end

    it "has ActiveModel naming conventions" do
      expect(ActiveReport.model_name.i18n_key).to eq(:active_report)
    end
  end

  describe ".param_name" do
    it "makes right param key from simple class name" do
      expect(ActiveReport.param_name).to eq("active_report")
    end

    it "makes right param key from class of module" do
      expect(Grid::ActiveReport.param_name).to eq("grid_active_report")
    end
  end
end
