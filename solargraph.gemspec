$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'solargraph/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'solargraph'
  s.version     = Solargraph::VERSION
  s.summary     = 'A Ruby language server'
  s.description = 'IDE tools for code completion, inline documentation, and static analysis'
  s.authors     = ['Fred Snyder']
  s.email       = 'admin@castwide.com'
  s.files       = Dir.chdir(File.expand_path(__dir__)) do
    # @sg-ignore Need backtick support
    # @type [String]
    all_files = `git ls-files -z`
    all_files.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.homepage    = 'https://solargraph.org'
  s.license     = 'MIT'
  s.executables = ['solargraph']
  s.metadata['funding_uri']     = 'https://www.patreon.com/castwide'
  s.metadata['bug_tracker_uri'] = 'https://github.com/castwide/solargraph/issues'
  s.metadata['changelog_uri']   = 'https://github.com/castwide/solargraph/blob/master/CHANGELOG.md'
  s.metadata['source_code_uri'] = 'https://github.com/castwide/solargraph'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'ast', '~> 2.4.3'
  s.add_dependency 'backport', '~> 1.2'
  s.add_dependency 'benchmark', '~> 0.4'
  s.add_dependency 'bundler', '~> 2.0'
  s.add_dependency 'diff-lcs', '~> 1.4'
  s.add_dependency 'jaro_winkler', '~> 1.6', '>= 1.6.1'
  s.add_dependency 'kramdown', '~> 2.3'
  s.add_dependency 'kramdown-parser-gfm', '~> 1.1'
  s.add_dependency 'logger', '~> 1.6'
  s.add_dependency 'observer', '~> 0.1'
  s.add_dependency 'open3', '~> 0.2.1'
  s.add_dependency 'ostruct', '~> 0.6'
  s.add_dependency 'parser', '~> 3.0'
  s.add_dependency 'prism', '~> 1.4'
  s.add_dependency 'rbs', ['>= 3.6.1', '<= 4.0.0.dev.4']
  s.add_dependency 'reverse_markdown', '~> 3.0'
  s.add_dependency 'rubocop', '~> 1.76'
  s.add_dependency 'thor', '~> 1.0'
  s.add_dependency 'tilt', '~> 2.0'
  s.add_dependency 'yard', '~> 0.9', '>= 0.9.24'
  s.add_dependency 'yard-activesupport-concern', '~> 0.0'
  s.add_dependency 'yard-solargraph', '~> 0.1'

  s.add_development_dependency 'pry', '~> 0.15'
  s.add_development_dependency 'public_suffix', '~> 3.1'
  s.add_development_dependency 'rake', '~> 13.2'
  s.add_development_dependency 'rspec', '~> 3.5'
  #
  # very specific development-time RuboCop version patterns for CI
  # stability - feel free to update in an isolated PR
  #
  # even more specific on RuboCop itself, which is written into _todo
  # file.
  s.add_development_dependency 'overcommit', '~> 0.68.0'
  s.add_development_dependency 'rubocop', '~> 1.80.0.0'
  s.add_development_dependency 'rubocop-rake', '~> 0.7.1'
  s.add_development_dependency 'rubocop-rspec', '~> 3.6.0'
  s.add_development_dependency 'rubocop-yard', '~> 1.0.0'
  s.add_development_dependency 'simplecov', '~> 0.21'
  s.add_development_dependency 'simplecov-lcov', '~> 0.8'
  s.add_development_dependency 'undercover', '~> 0.7'
  s.add_development_dependency 'webmock', '~> 3.6'
  # work around missing yard dependency needed as of Ruby 3.5
  s.add_development_dependency 'irb', '~> 1.15'
end
