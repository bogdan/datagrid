require 'spec_helper'

describe Datagrid::Core do

  context 'with 2 persisted entries' do
    before { 2.times { Entry.create } }

    let(:report_class) do
      test_report_class do
        scope { Entry.order("id desc") }
      end
    end

    describe '#scope' do
      context 'in the class' do
        let(:report) { report_class.new }

        it { expect(report.scope.to_a.size).to eq(2) }
      end

      context 'changes scope on the fly' do
        let(:report) do
          report_class.new.tap do |r|
            r.scope { Entry.limit(1)}
          end
        end

        it { expect(report.scope.to_a.size).to eq(1) }
      end

      context 'overriding scope by initializer' do
        let(:report) { report_class.new { Entry.limit(1) } }

        it { expect(report.scope.to_a.size).to eq(1) }

        context "reset scope to default" do
          before do
            report.reset_scope
          end
          it { expect(report.scope.to_a.size).to eq(2) }
        end
      end

      context "appending scope by initializer " do
        let(:report) { report_class.new {|scope| scope.limit(1)} }
        it { expect(report.scope.to_a.size).to eq(1) }
        it { expect(report.scope.order_values.size).to eq(1) }
      end
    end
  end

  describe ".inspect" do
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
end
