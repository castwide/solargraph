source 'https://rubygems.org'

gemspec name: 'solargraph'

# allow rubocop-yard to understand literal symbols in type annotations
gem 'yard', github: 'apiology/yard', branch: 'literal_symbols', require: false

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
