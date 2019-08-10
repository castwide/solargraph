source 'https://rubygems.org'

gemspec name: 'solargraph'

if RUBY_VERSION =~ /^2\.(1|2)\./
  gem 'kramdown', '~> 1.16'
else
  gem 'kramdown', '~> 2.0'
  gem 'kramdown-parser-gfm', '~> 1.0'
end

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
