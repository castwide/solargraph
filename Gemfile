# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'solargraph'

# Test fixture gems
gem 'gem-with-yard-macros', path: 'spec/fixtures/gem-with-yard-macros'

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path('.Gemfile', __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
