# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "datagrid/version"

Gem::Specification.new do |s|
  s.name = "datagrid"
  s.version = Datagrid::VERSION
  s.require_paths = ["lib"]
  s.authors = ["Bogdan Gusiev"]
  s.date = "2020-09-07"
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
  s.homepage = "http://github.com/bogdan/datagrid"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0")
  s.rubygems_version = "3.0.8"
  url = 'https://github.com/bogdan/datagrid'
  s.metadata = {
    "homepage_uri" => url,
    "bug_tracker_uri" => "#{url}/issues",
    "documentation_uri" => "#{url}/wiki",
    "changelog_uri" => "#{url}/blob/master/CHANGELOG.md",
    "source_code_uri" => url,
  }

  s.add_dependency(%q<rails>, [">= 4.0"])
end

