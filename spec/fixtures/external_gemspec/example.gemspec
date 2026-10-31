# frozen_string_literal: true

# @param s [Gem::Specification]
Gem::Specification.new do |s|
  s.name        = 'example'
  s.version     = '1.0.0'
  s.summary     = 'Example gemspec for Solargraph tests'
  s.authors     = ['Fred Snyder']
  s.email       = 'example@example.com'
  s.files       = Dir.chdir(File.expand_path(__dir__)) do
    # @sg-ignore Need backtick support
    # @type [String]
    all_files = `git ls-files -z`
    all_files.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version = '>= 3.1'

  s.add_dependency 'backport', '~> 1.2'

  s.add_development_dependency 'rspec', '~> 3.5'
end
