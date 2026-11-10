# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'gem-with-delegated-rbs'
  spec.version = '0.1.0'
  spec.authors = ['Solargraph']
  spec.summary = 'A gem whose RBS types a Forwardable delegation'
  spec.required_ruby_version = '>= 3.1'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'sig/**/*.rbs']
  spec.require_paths = ['lib']
end
