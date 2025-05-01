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

  describe 'initialize' do
    subject do
      class DefaultOptionsGrid < Datagrid::Base
        self.default_column_options = { html: true }
      end

      Datagrid::Columns::Column.new(DefaultOptionsGrid, :id, "id", {})
    end

    it 'correctly inherits default options' do
      expect(subject.options).to match(html: true)
    end
  end
end
