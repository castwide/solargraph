source 'https://rubygems.org'

gemspec name: 'solargraph'

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile

platforms :mri do
  gem 'fast_trie', '~> 0.5.1'
end
