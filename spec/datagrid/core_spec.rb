# frozen_string_literal: true

require "spec_helper"
require "action_controller/metal/strong_parameters"

describe Datagrid::Core do
  describe "#original_scope" do
    it "does not wrap instance scope" do
      grid = test_grid

      expect(grid.original_scope).to eq(Entry)
    end

    it "does not wrap class scope" do
      klass = test_grid_class do
        scope { Entry }
      end

      expect(klass.original_scope).to eq(Entry)
    end
  end

  context "with 2 persisted entries" do
    before { 2.times { Entry.create } }

    let(:report_class) do
      class ScopeTestReport < Datagrid::Base
        scope { Entry.order("id desc") }
      end
      ScopeTestReport
    end

    describe "#scope" do
      it "wraps scope" do
        grid = test_grid
        expect(grid.scope).to be_a(ActiveRecord::Relation)
      end

      context "in the class" do
        let(:report) { report_class.new }

        it { expect(report.scope.to_a.size).to eq(2) }
        it { expect(report).not_to be_redefined_scope }

        context "when redefined" do
          it "accepts previous scope" do
            module Ns83827
              class TestGrid < ScopeTestReport
                scope do |previous|
                  previous.reorder("id asc")
                end
              end
            end

            expect(Ns83827::TestGrid.new.assets.order_values).to eq(["id asc"])
          end
        end
      end

      context "changes scope on the fly" do
        let(:report) do
          report_class.new.tap do |r|
            r.scope { Entry.limit(1) }
          end
        end

        it { expect(report.scope.to_a.size).to eq(1) }
        it { expect(report).to be_redefined_scope }
      end

      context "overriding scope by initializer" do
        let(:report) { report_class.new { Entry.limit(1) } }

        it { expect(report).to be_redefined_scope }
        it { expect(report.scope.to_a.size).to eq(1) }

        context "reset scope to default" do
          before do
            report.reset_scope
          end

          it { expect(report.scope.to_a.size).to eq(2) }
          it { expect(report).not_to be_redefined_scope }
        end
      end

      context "appending scope by initializer" do
        let(:report) { report_class.new { |scope| scope.limit(1) } }

        it { expect(report.scope.to_a.size).to eq(1) }
        it { expect(report.scope.order_values.size).to eq(1) }
        it { expect(report).to be_redefined_scope }
      end
    end
  end

  describe "#inspect" do
    it "shows all attribute values" do
      class InspectTest < Datagrid::Base
        scope { Entry }
        filter(:created_at, :date, range: true)
        column(:name)
      end

      grid = InspectTest.new(created_at: %w[2014-01-01 2014-08-05], descending: true, order: "name")
      expect(grid.inspect).to eq(
        "#<InspectTest order: :name, descending: true, created_at: Wed, 01 Jan 2014..Tue, 05 Aug 2014>",
      )
    end
  end

  describe "#==" do
    class EqualTest < Datagrid::Base
      scope { Entry }
      filter(:created_at, :date)
      column(:name)
      column(:created_at)
    end
    it "work on empty objects" do
      expect(EqualTest.new).to eq(EqualTest.new)
    end

    it "sees the difference on the filter value" do
      expect(EqualTest.new(created_at: Date.yesterday)).not_to eq(EqualTest.new(created_at: Date.today))
    end

    it "sees the difference on order" do
      expect(EqualTest.new(order: :created_at)).not_to eq(EqualTest.new(order: :name))
    end

    it "doesn't destinguish between String and Symbol order" do
      expect(EqualTest.new(order: :created_at)).to eq(EqualTest.new(order: "created_at"))
    end

    it "checks for redefined scope" do
      expect(EqualTest.new).not_to eq(EqualTest.new { |s| s.reorder(:name) })
    end
  end

  describe "dynamic helper" do
    it "works" do
      grid = test_grid do
        scope { Entry }
        column(:id)
        dynamic do
          column(:name)
          column(:category)
        end
      end

      expect(grid.columns.map(&:name)).to eq(%i[id name category])
      expect(grid.class.columns.map(&:name)).to eq([:id])

      expect(grid.column_by_name(:id)).not_to be_nil
      expect(grid.column_by_name(:name)).not_to be_nil
    end

    it "has access to attributes" do
      grid = test_grid(attribute_name: "value") do
        scope { Entry }
        datagrid_attribute :attribute_name
        dynamic do
          value = attribute_name
          column(:name) { value }
        end
      end

      expect(grid.data_value(:name, Entry.create!)).to eq("value")
    end

    it "applies before instance scope" do
      klass = test_grid_class do
        scope { Entry }
        dynamic do
          scope do |s|
            s.limit(1)
          end
        end
      end

      grid = klass.new do |s|
        s.limit(2)
      end

      expect(grid.assets.limit_value).to eq(2)
    end

    it "has access to grid attributes within scope" do
      grid = test_grid(name: "one") do
        scope { Entry }
        dynamic do
          scope do |s|
            s.where(name: name)
          end
        end
        filter(:name, dummy: true)
      end
      one = Entry.create!(name: "one")
      two = Entry.create!(name: "two")
      expect(grid.assets).to include(one)
      expect(grid.assets).not_to include(two)
    end
  end

  describe "ActionController::Parameters" do
    let(:params) do
      ActionController::Parameters.new(name: "one")
    end

    it "permites all attributes by default" do
      grid = test_grid(params) do
        scope { Entry }
        filter(:name)
      end

      expect(grid.name).to eq("one")
    end

    it "doesn't permit attributes when forbidden_attributes_protection is set" do
      expect do
        test_grid(params) do
          scope { Entry }
          self.forbidden_attributes_protection = true
          filter(:name)
        end
      end.to raise_error(ActiveModel::ForbiddenAttributesError)
    end

    it "permits attributes when forbidden_attributes_protection is set and attributes are permitted" do
      expect do
        test_grid(params.permit!) do
          scope { Entry }
          self.forbidden_attributes_protection = true
          filter(:name)
        end
      end.not_to raise_error
    end

    it "supports hash attribute assignment" do
      grid = test_grid_filter(:group_id, :integer, range: true)
      grid.attributes = ActionController::Parameters.new(group_id: { from: 1, to: 2 })

      expect(grid.group_id).to eq(1..2)
    end
  end

  describe ".query_param" do
    it "works" do
      grid = test_grid(name: "value") do
        scope { Entry }
        filter(:name)
        def param_name
          "grid"
        end
      end
      expect(grid.query_params).to eq({ grid: { name: "value" } })
    end
  end
end
