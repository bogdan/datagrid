# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Columns::Column do
  describe ".inspect" do
    subject do
      class ColumnInspectTest < Datagrid::Base
        scope { Entry }
        column(:id, header: "ID")
      end
      ColumnInspectTest.column_by_name(:id)
    end

    it "shows inspect information" do
      expect(subject.inspect).to eq('#<Datagrid::Columns::Column ColumnInspectTest#id {:header=>"ID"}>')
    end
  end
end
