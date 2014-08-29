require "rails/generators"

class Datagrid::Scaffold < Rails::Generators::NamedBase
  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_scaffold
    template "grid.rb.erb", "app/grids/#{grid_class_name.underscore}.rb"
    template "controller.rb.erb", "app/controllers/#{grid_controller_name.underscore}.rb"
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

  def grid_controller_short_name
    file_name.underscore.pluralize
  end

  def grid_model_name
    file_name.camelize.singularize
  end

  def grid_ivar_name
    grid_class_name.underscore
  end

  def paginate_code
    "page(params[:page])"
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

end
