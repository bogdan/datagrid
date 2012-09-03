class DatagridGenerator < Rails::Generators::NamedBase
  source_root File.expand_path(__FILE__ + "/../../../generator")

  def create_uploader_file
    template "grid_template.rb.erb", "app/grids/#{file_name}_grid.rb"
  end
end
