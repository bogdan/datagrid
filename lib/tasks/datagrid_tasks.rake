namespace :datagrid do

  def copy_template(path)
    gem_app   = File.expand_path("../../../app", __FILE__)
    rails_app = (Rails.root + "app").to_s
    puts "* copy (#{path})"
    sh "mkdir -p #{rails_app}/#{File.dirname path}"
    cp "#{gem_app}/#{path}", "#{rails_app}/#{path}"
  end

  desc "Copy table partials into rails application"
  task :copy_partials do
    copy_template "views/datagrid/_table.html.erb"
    copy_template "views/datagrid/_head.html.erb"
    copy_template "views/datagrid/_row.html.erb"
  end

end
