# frozen_string_literal: true
# coding: utf-8

lib = File.expand_path("../lib/", __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require_relative "wordgraph/version"

Gem::Specification.new do |spec|
  spec.name = "wordgraph"
  spec.version = Wordgraph::VERSION
  spec.licenses = %w(MIT)
  spec.authors = ["marm00"]
  spec.email = [""]
  spec.description = "Wordgraph"
  spec.summary = spec.description
  spec.homepage = "https://github.com/marm00/wordgraph"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/marm00/wordgraph/issues",
    "changelog_uri" => spec.homepage,
    "documentation_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/marm00/wordgraph/tree/main",
    "wiki_uri" => spec.homepage,
  }

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = %w(.document wordgraph.gemspec) + Dir["*.md", "bin/*", "lib/**/*.rb"]
  spec.executables = %w(wordgraph)
  spec.require_paths = %w(lib)

  spec.add_dependency "optparse", "~> 0.6.0"
end
