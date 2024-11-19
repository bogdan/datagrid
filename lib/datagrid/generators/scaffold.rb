# frozen_string_literal: true

require "rails/generators"

module Datagrid
  # @!visibility private
  module Generators
    # @!visibility private
    class Scaffold < Rails::Generators::NamedBase
      include Rails::Generators::ResourceHelpers

      check_class_collision suffix: "Grid"
      source_root File.expand_path("#{__FILE__}/../../../templates")

      def create_scaffold
        template "base.rb.erb", base_grid_file unless file_exists?(base_grid_file)
        template "grid.rb.erb", "app/grids/#{grid_class_name.underscore}.rb"
        if file_exists?(grid_controller_file)
          inject_into_file grid_controller_file, index_action, after: %r{class .*#{grid_controller_class_name}.*\n}
        else
          create_file grid_controller_file, controller_code
        end
        create_file view_file, view_code
        route(generate_routing_namespace("resources :#{grid_controller_short_name}"))
        gem "kaminari" unless kaminari? || will_paginate? || pagy?
        in_root do
          {
            "css" => " *= require datagrid",
            "css.sass" => " *= require datagrid",
            "css.scss" => " *= require datagrid",
          }.each do |extension, string|
            file = "app/assets/stylesheets/application.#{extension}"
            if file_exists?(file)
              inject_into_file file, "#{string}\n", { before: %r{.*require_self} } # before all
            end
          end
        end
      end

      def view_file
        Rails.root.join("app/views").join(controller_file_path).join("index.html.erb")
      end

      def grid_class_name
        "#{file_name.camelize.pluralize}Grid"
      end

      def grid_base_class
        file_exists?("app/grids/base_grid.rb") ? "BaseGrid" : "ApplicationGrid"
      end

      def grid_controller_class_name
        "#{controller_class_name.camelize}Controller"
      end

      def grid_controller_file
        Rails.root.join("app/controllers").join("#{grid_controller_class_name.underscore}.rb")
      end

      def grid_controller_short_name
        controller_file_name
      end

      def grid_model_name
        file_name.camelize.singularize
      end

      def grid_param_name
        grid_class_name.underscore
      end

      def pagination_helper_code
        if will_paginate?
          "will_paginate(@grid.assets)"
        elsif pagy?
          "pagy_nav(@pagy)"
        else
          # Kaminari is default
          "paginate(@grid.assets)"
        end
      end

      def table_helper_code
        if pagy?
          "datagrid_table @grid, @records"
        else
          "datagrid_table @grid"
        end
      end

      def base_grid_file
        "app/grids/application_grid.rb"
      end

      def grid_route_name
        "#{controller_class_name.underscore.gsub('/', '_')}_path"
      end

      def index_code
        if pagy?
          <<-RUBY
    @grid = #{grid_class_name}.new(grid_params)
    @pagy, @assets = pagy(@grid.assets)
          RUBY
        else
          <<-RUBY
    @grid = #{grid_class_name}.new(grid_params) do |scope|
      scope.page(params[:page])
    end
          RUBY
        end
      end

      def controller_code
        <<~RUBY
          class #{grid_controller_class_name} < ApplicationController
            def index
          #{index_code.rstrip}
            end

            protected

            def grid_params
              params.fetch(:#{grid_param_name}, {}).permit!
            end
          end
        RUBY
      end

      def view_code
        <<~ERB
          <%= datagrid_form_with model: @grid, url: #{grid_route_name} %>

          <%= #{pagination_helper_code} %>
          <%= #{table_helper_code} %>
          <%= #{pagination_helper_code} %>
        ERB
      end

      protected

      def generate_routing_namespace(code)
        depth = regular_class_path.length
        # Create 'namespace' ladder
        # namespace :foo do
        #   namespace :bar do
        namespace_ladder = regular_class_path.each_with_index.map do |ns, i|
          indent("namespace :#{ns} do\n", i * 2)
        end.join

        # Create route
        #     get 'baz/index'
        route = indent(code, depth * 2)

        # Create `end` ladder
        #   end
        # end
        end_ladder = (1..depth).reverse_each.map do |i|
          indent("end\n", i * 2)
        end.join

        # Combine the 3 parts to generate complete route entry
        "#{namespace_ladder}#{route}\n#{end_ladder}"
      end

      def file_exists?(name)
        name = Rails.root.join(name) unless name.to_s.first == "/"
        File.exist?(name)
      end

      def pagy?
        defined?(::Pagy)
      end

      def will_paginate?
        defined?(::WillPaginate)
      end

      def kaminari?
        defined?(::Kaminari)
      end
    end
  end
end
