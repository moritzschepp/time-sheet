# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "time_sheet/version"

Gem::Specification.new do |spec|
  spec.name          = "time-sheet"
  spec.version       = TimeSheet::VERSION
  spec.authors       = ["Moritz Schepp"]
  spec.email         = ["moritz.schepp@gmail.com"]
  spec.license       = 'GPL-3.0-only'

  spec.summary       = "a time tracking solution based on spreadsheets"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/moritzschepp/time-sheet/issues",
    "documentation_uri" => "https://github.com/moritzschepp/time-sheet"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'spreadsheet'
  spec.add_dependency 'slop'

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'pry'
end
