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

        it { expect(report.scope.to_a).to have(2).item }
      end

      context 'changes scope on the fly' do
        let(:report) do
          report_class.new.tap do |r|
            r.scope { Entry.limit(1)}
          end
        end

        it { expect(report.scope.to_a).to have(1).item }
      end

      context 'overriding scope by initializer' do
        let(:report) { report_class.new { Entry.limit(1) } }

        it { expect(report.scope.to_a).to have(1).item }

        context "reset scope to default" do
          before do
            report.reset_scope
          end
          it { expect(report.scope.to_a).to have(2).item }
        end
      end

      context "appending scope by initializer " do
        let(:report) { report_class.new {|scope| scope.limit(1)} }
        it { expect(report.scope.to_a).to have(1).item }
        it { expect(report.scope.order_values).to have(1).item }
      end
    end
  end
end
