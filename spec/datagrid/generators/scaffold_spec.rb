# frozen_string_literal: true

require "spec_helper"

describe Datagrid::Generators::Scaffold do
  subject { described_class.new(["user"]) }

  describe ".pagination_helper_code" do
    it "uses kaminari by default" do
      expect(subject.pagination_helper_code).to eql("paginate(@grid.assets)")
    end

    context "when WillPaginate exists" do
      before do
        Object.const_set("WillPaginate", 1)
      end

      after do
        Object.send(:remove_const, "WillPaginate")
      end

      it "uses willpaginate" do
        expect(subject.pagination_helper_code).to eql("will_paginate(@grid.assets)")
      end
    end
  end

  describe "#controller_code" do
    it "works" do
      expect(subject.controller_code).to eq(<<~RUBY)
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

    context "with pagy" do
      before do
        allow(subject).to receive(:pagy?).and_return(true)
      end

      it "works" do
        expect(subject.controller_code).to eq(<<~RUBY)
          class UsersController < ApplicationController
            def index
              @grid = UsersGrid.new(grid_params)
              @pagy, @assets = pagy(@grid.assets)
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

  describe "#view_code" do
    it "works" do
      expect(subject.view_code).to eq(<<~ERB)
        <%= datagrid_form_with model: @grid, url: users_path %>

        <%= paginate(@grid.assets) %>
        <%= datagrid_table @grid %>
        <%= paginate(@grid.assets) %>
      ERB
    end

    context "with pagy" do
      before do
        allow(subject).to receive(:pagy?).and_return(true)
      end

      it "works" do
        expect(subject.view_code).to eq(<<~ERB)
          <%= datagrid_form_with model: @grid, url: users_path %>

          <%= pagy_nav(@pagy) %>
          <%= datagrid_table @grid, @records %>
          <%= pagy_nav(@pagy) %>
        ERB
      end
    end
  end
end
