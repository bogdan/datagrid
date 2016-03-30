require "rails/generators"

class Datagrid::Scaffold < Rails::Generators::NamedBase

  include Rails::Generators::ResourceHelpers

  check_class_collision :suffix => "Grid"
  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_scaffold
    template "grid.rb.erb", "app/grids/#{grid_class_name.underscore}.rb"
    if File.exists?(grid_controller_file)
      inject_into_file grid_controller_file, index_action, :after => %r{class .*#{grid_controller_name}.*\n}
    else
      template "controller.rb.erb", grid_controller_file
    end
    template "index.html.erb", "app/views/#{grid_controller_short_name}/index.html.erb"
    route("resources :#{grid_controller_short_name}")
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

  def grid_class_name
    file_name.camelize.pluralize + "Grid"
  end

  def grid_controller_name
    grid_controller_short_name.camelize + "Controller"
  end

  def grid_controller_file
    Rails.root.join("app/controllers/#{grid_controller_name.underscore}.rb")
  end

  def grid_controller_short_name
    file_name.underscore.pluralize
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
    grid_controller_short_name + "_path"
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

end
