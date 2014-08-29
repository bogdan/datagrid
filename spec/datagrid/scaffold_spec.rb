require 'spec_helper'

describe Datagrid::Scaffold do
  subject { Datagrid::Scaffold.new([""]) }

  describe '.paginate_code' do
    it 'should fall through options successfully' do
      expect(subject.paginate_code).to eql('page(params[:page])')
    end
  end

  describe '.pagination_helper_code' do
    it 'should fall through options successfully' do
      expect(subject.pagination_helper_code).to eql('paginate(@grid.assets)')
    end

    context "when Kaminari exists" do
      before(:each) do
        Object.const_set("Kaminari", 1)
      end
      it 'should fall through options successfully' do
        expect(subject.pagination_helper_code).to eql('paginate(@grid.assets)')
      end

      after(:each) do
        Object.send(:remove_const, "Kaminari")
      end
    end
  end
end
