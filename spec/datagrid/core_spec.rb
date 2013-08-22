require 'spec_helper'

describe Datagrid::Core do

  context 'with 2 persisted entries' do
    before { 2.times { Entry.create } }

    let(:limit) { Entry.limit(1) }
    let(:report_class) do
      test_report_class do
        scope { Entry }
      end
    end

    describe '#scope' do
      context 'in the class' do
        let(:report) { report_class.new }

        it { expect(report.scope).to have(2).item }
      end

      context 'changes scope on the fly' do
        let(:report) do
          report_class.new.tap do |r|
            r.scope { limit }
          end
        end

        it { expect(report.scope).to have(1).item }
      end

      context 'changes scope by initializer' do
        let(:report) { report_class.new { limit } }

        it { expect(report.scope).to have(1).item }
      end
    end
  end
end
