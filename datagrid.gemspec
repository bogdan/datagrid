# frozen_string_literal: true

require_relative "lib/datagrid/version"

Gem::Specification.new do |s|
  s.name = "datagrid"
  s.version = Datagrid::VERSION
  s.require_paths = ["lib"]
  s.authors = ["Bogdan Gusiev"]
  s.summary = "Ruby gem to create datagrids"
  s.description = "This allows you to easily build datagrid aka data tables with sortable columns and filters"
  s.email = "agresso@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "Readme.markdown"
  ]
  s.files = [
    "LICENSE.txt",
    "CHANGELOG.md",
    "Readme.markdown",
    "datagrid.gemspec",
  ]
  s.files += `git ls-files | grep -E '^(app|lib|templates)'`.split("\n")
  s.homepage = "https://github.com/bogdan/datagrid"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7")
  s.metadata = {
    "homepage_uri" => s.homepage,
    "bug_tracker_uri" => "#{s.homepage}/issues",
    "documentation_uri" => "#{s.homepage}/wiki",
    "changelog_uri" => "#{s.homepage}/blob/master/CHANGELOG.md",
    "source_code_uri" => s.homepage,
  }

  s.add_dependency "railties", ">= 6.0"
end

