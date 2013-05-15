namespace :datagrid do

  desc "Copy table partials into rails application"
  task :copy_partials do
    require "fileutils"
    views_path = "app/views/datagrid"
    destination_dir = (Rails.root + views_path).to_s
    pattern = File.expand_path(File.dirname(__FILE__) + "/../../#{views_path}") + "/*"
    Dir[pattern].each do |template|
      puts "* copy #{template} => #{destination_dir}"
      FileUtils.mkdir_p destination_dir
      FileUtils.cp template, destination_dir
    end
  end
end
