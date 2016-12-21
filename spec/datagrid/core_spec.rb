require 'spec_helper'

describe Datagrid::Core do

  context 'with 2 persisted entries' do
    before { 2.times { Entry.create } }

    let(:report_class) do
      class ScopeTestReport
        include Datagrid
        scope { Entry.order("id desc") }
      end
      ScopeTestReport
    end

    describe '#scope' do
      context 'in the class' do
        let(:report) { report_class.new }

        it { expect(report.scope.to_a.size).to eq(2) }
        it { expect(report).to_not be_redefined_scope }

        context "when redefined" do
          it "should accept previous scope" do
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

      context 'changes scope on the fly' do
        let(:report) do
          report_class.new.tap do |r|
            r.scope { Entry.limit(1)}
          end
        end

        it { expect(report.scope.to_a.size).to eq(1) }
        it { expect(report).to be_redefined_scope }
      end

      context 'overriding scope by initializer' do
        let(:report) { report_class.new { Entry.limit(1) } }

        it { expect(report).to be_redefined_scope }
        it { expect(report.scope.to_a.size).to eq(1) }

        context "reset scope to default" do
          before do
            report.reset_scope
          end
          it { expect(report.scope.to_a.size).to eq(2) }
          it { expect(report).to_not be_redefined_scope }
        end
      end

      context "appending scope by initializer " do
        let(:report) { report_class.new {|scope| scope.limit(1)} }
        it { expect(report.scope.to_a.size).to eq(1) }
        it { expect(report.scope.order_values.size).to eq(1) }
        it { expect(report).to be_redefined_scope }
      end
    end
  end

  describe "#inspect" do
    it "should show all attribute values" do
      class InspectTest
        include Datagrid
        scope {Entry}
        filter(:created_at, :date, :range => true)
        column(:name)
      end

      grid = InspectTest.new(:created_at => ['2014-01-01', '2014-08-05'], :descending => true, :order => 'name')
      expect(grid.inspect).to eq('#<InspectTest order: :name, descending: true, created_at: [Wed, 01 Jan 2014, Tue, 05 Aug 2014]>')
    end
  end

  describe "#==" do
    class EqualTest
      include Datagrid
      scope {Entry}
      filter(:created_at, :date)
      column(:name)
      column(:created_at)
    end
    it "work on empty objects" do
      expect(EqualTest.new).to eq(EqualTest.new)
    end
    it "sees the difference on the filter value" do
      expect(EqualTest.new(created_at: Date.yesterday)).to_not eq(EqualTest.new(created_at: Date.today))
    end
    it "sees the difference on order" do
      expect(EqualTest.new(order: :created_at)).to_not eq(EqualTest.new(order: :name))
    end
    it "doesn't destinguish between String and Symbol order" do
      expect(EqualTest.new(order: :created_at)).to eq(EqualTest.new(order: "created_at"))
    end
    it "checks for redefined scope" do
      expect(EqualTest.new).to_not eq(EqualTest.new {|s| s.reorder(:name)})
    end
  end
end
