require 'spec_helper'

describe Datagrid::Scaffold do
  subject { Datagrid::Scaffold.new(["user"]) }


  describe '.pagination_helper_code' do
    it 'uses kaminari by default' do
      expect(subject.pagination_helper_code).to eql('paginate(@grid.assets)')
    end

    context "when WillPaginate exists" do
      before(:each) do
        Object.const_set("WillPaginate", 1)
      end
      it 'uses willpaginate' do
        expect(subject.pagination_helper_code).to eql('will_paginate(@grid.assets)')
      end

      after(:each) do
        Object.send(:remove_const, "WillPaginate")
      end
    end
  end

  describe ".index_action" do

    it "works" do
      expect(subject.index_action).to eq(<<-RUBY)
  def index
    @grid = UsersGrid.new(params[:users_grid]) do |scope|
      scope.page(params[:page])
    end
  end
RUBY
    end

  end
end
