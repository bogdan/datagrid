require "rails/generators"

class Datagrid::Scaffold < Rails::Generators::NamedBase

  include Rails::Generators::ResourceHelpers

  check_class_collision :suffix => "Grid"
  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_scaffold
    template "grid.rb.erb", "app/grids/#{grid_class_name.underscore}.rb"
    if File.exists?(grid_controller_file)
      inject_into_file grid_controller_file, index_action, :after => %r{class .*#{grid_controller_class_name}.*\n}
    else
      template "controller.rb.erb", grid_controller_file
    end
    template "index.html.erb", view_file
    route(generate_routing_namespace("resources :#{grid_controller_short_name}"))
    unless defined?(::Kaminari) || defined?(::WillPaginate)
      gem 'kaminari'
    end
    in_root do
      {
        "css" => " *= require datagrid",
        "css.sass" => " *= require datagrid",
        "css.scss" => " *= require datagrid",
      }.each do |extension, string|
        file = "app/assets/stylesheets/application.#{extension}"
        if File.exists?(Rails.root.join(file))
          inject_into_file file, string + "\n", {:before => %r{.*require_self}} # before all
        end
      end
    end
  end

  def view_file
    Rails.root.join("app/views").join(controller_file_path).join("index.html.erb")
  end

  def grid_class_name
    file_name.camelize.pluralize + "Grid"
  end

  def grid_controller_class_name
    controller_class_name.camelize + "Controller"
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
    if defined?(::WillPaginate)
      "will_paginate(@grid.assets)"
    else
      # Kaminari is default
      "paginate(@grid.assets)"
    end

  end

  def grid_route_name
    controller_class_name.underscore.gsub("/", "_") + "_path"
  end

  def index_action
    indent(<<-RUBY)
def index
  @grid = #{grid_class_name}.new(params[:#{grid_param_name}]) do |scope|
    scope.page(params[:page])
  end
end
RUBY
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
    namespace_ladder + route + "\n" + end_ladder
  end
end
