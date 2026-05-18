# frozen_string_literal: true

require_relative "lib/gem/with/yard/macros/version"

Gem::Specification.new do |spec|
  spec.name = "gem-with-yard-macros"
  spec.version = Gem::With::Yard::Macros::VERSION
  spec.authors = ["Lekë Mula"]
  spec.email = ["leke.mula@gmail.com"]

  spec.summary = "Test fixture for Solargraph's YARD macro support."
  spec.description = "Provides a class with a `@!macro`-decorated DSL method, used by Solargraph specs to verify gem-defined macro loading."
  spec.homepage = "https://github.com/castwide/solargraph"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
end
