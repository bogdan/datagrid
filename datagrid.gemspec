# frozen_string_literal: true

require_relative "lib/datagrid/version"

Gem::Specification.new do |s|
  s.name = "datagrid"
  s.version = Datagrid::VERSION
  s.require_paths = ["lib"]
  s.authors = ["Bogdan Gusiev"]
  s.summary = "Library that provides DSL to present table like data"
  s.description = "The library allows you to easily build datagrid aka data tables with sortable columns and filters"
  s.email = "agresso@gmail.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
  ]
  s.files = [
    "LICENSE.txt",
    "CHANGELOG.md",
    "README.md",
    "datagrid.gemspec",
  ]
  s.files += `git ls-files | grep -E '^(app|lib|templates)'`.split("\n")
  s.homepage = "https://github.com/bogdan/datagrid"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0")
  s.metadata = {
    "homepage_uri" => s.homepage,
    "bug_tracker_uri" => "#{s.homepage}/issues",
    "documentation_uri" => "#{s.homepage}/wiki",
    "changelog_uri" => "#{s.homepage}/blob/main/CHANGELOG.md",
    "source_code_uri" => s.homepage,
    "rubygems_mfa_required" => "true",
  }

  s.add_dependency "railties", ">= 7.0"
end
