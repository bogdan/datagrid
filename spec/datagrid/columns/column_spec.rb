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
      # Ruby 3.4+ changed Hash#inspect format for symbol keys from {:key=>"value"} to {key: "value"}
      expected = if RUBY_VERSION >= "3.4"
        '#<Datagrid::Columns::Column ColumnInspectTest#id {header: "ID"}>'
      else
        '#<Datagrid::Columns::Column ColumnInspectTest#id {:header=>"ID"}>'
      end
      expect(subject.inspect).to eq(expected)
    end
  end

  describe 'initialize' do
    subject do
      class DefaultOptionsGrid < Datagrid::Base
        self.default_column_options = { html: true }
        scope { Entry }
        column(:id)
      end
    end

    it 'correctly inherits default options' do
      expect(subject.options).to match(html: true)
    end
  end
end
