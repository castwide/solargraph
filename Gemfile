# frozen_string_literal: true

source 'https://rubygems.org'

gemspec name: 'solargraph'

# Test fixture gems
gem 'gem-with-yard-macros', path: 'spec/fixtures/gem-with-yard-macros'

# rubocop-yard 1.3 fixes YARD CollectionStyle crashes under yard 0.9.44
# but requires Ruby >= 3.3, and a gemspec cannot express that condition.
# Specs run on 3.1 and 3.2, which keep 1.0.x.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3.0')
  gem 'rubocop-yard', '~> 1.3.0'
else
  gem 'rubocop-yard', '~> 1.0.0'
end

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path('.Gemfile', __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
