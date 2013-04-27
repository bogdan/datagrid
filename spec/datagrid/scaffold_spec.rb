require 'spec_helper'

describe Datagrid::Scaffold do
  subject { Datagrid::Scaffold.new([""]) }

  describe '.paginate_code' do
    it 'should fall through options successfully' do
      subject.paginate_code.should eql('paginate_somehow')
    end
  end

  describe '.pagination_helper_code' do
    it 'should fall through options successfully' do
      subject.pagination_helper_code.should eql('some_pagination_helper(@assets)')
    end
  end
end
