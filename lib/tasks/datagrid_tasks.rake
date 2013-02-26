namespace :datagrid do

  desc "Copy table partials into rails application"
  task :copy_partials do
    require "fileutils"
    def copy_template(path)
      gem_app   = File.expand_path("../../../app", __FILE__)
      rails_app = (Rails.root + "app").to_s
      full_path = "#{rails_app}/#{File.dirname path}"
      puts "* copy #{full_path}"
      FileUtils.mkdir_p full_path
      FileUtils.cp "#{gem_app}/#{path}", full_path
    end
    copy_template "views/datagrid/_table.html.erb"
    copy_template "views/datagrid/_head.html.erb"
    copy_template "views/datagrid/_order_for.html.erb"
    copy_template "views/datagrid/_row.html.erb"
  end

end
