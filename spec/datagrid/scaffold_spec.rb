# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Scaffold do
  subject { Datagrid::Scaffold.new(["user"]) }

  describe ".pagination_helper_code" do
    it "uses kaminari by default" do
      expect(subject.pagination_helper_code).to eql("paginate(@grid.assets)")
    end

    context "when WillPaginate exists" do
      before(:each) do
        Object.const_set("WillPaginate", 1)
      end
      it "uses willpaginate" do
        expect(subject.pagination_helper_code).to eql("will_paginate(@grid.assets)")
      end

      after(:each) do
        Object.send(:remove_const, "WillPaginate")
      end
    end
  end

  describe ".controller_code" do
    it "works" do
      expect(subject.controller_code).to eq(<<-RUBY)
class UsersController < ApplicationController
  def index
    @grid = UsersGrid.new(grid_params) do |scope|
      scope.page(params[:page])
    end
  end

  protected

  def grid_params
    params.fetch(:users_grid, {}).permit!
  end
end
RUBY
    end
  end
end
