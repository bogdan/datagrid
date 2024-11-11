module Datagrid
  module Generators
    class Views < Rails::Generators::Base
      source_root File.expand_path("../../../app/views/datagrid", __dir__)

      desc "Copies Datagrid partials to your application."
      def copy_views
        Dir.glob(File.join(self.class.source_root, "**", "*")).each do |file_path|
          relative_path = file_path.sub(self.class.source_root + "/", "")

          next if relative_path == "_order_for.html.erb"

          copy_file(relative_path, File.join("app/views/datagrid", relative_path))
        end
      end
    end
  end
end
