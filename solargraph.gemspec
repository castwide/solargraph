$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'
require 'solargraph/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'solargraph'
  s.version     = Solargraph::VERSION
  s.date        = Date.today.strftime("%Y-%m-%d")
  s.summary     = "Solargraph for Ruby"
  s.description = "IDE tools for code completion and inline documentation"
  s.authors     = ["Fred Snyder"]
  s.email       = 'admin@castwide.com'
  s.files       = Dir['lib/**/*'] + Dir['yardoc/**/*'] + ['.yardopts']
  s.homepage    = 'http://solargraph.org'
  s.license     = 'MIT'
  s.executables   = ['solargraph', 'solargraph-runtime']

  s.required_ruby_version = '>= 2.2.2'
  s.add_runtime_dependency 'parser', '~> 2.4'
  s.add_runtime_dependency 'thor', '~> 0.19', '>= 0.19.4'
  s.add_runtime_dependency 'sinatra', '~> 2'
  s.add_runtime_dependency 'yard', '~> 0.9'
  s.add_runtime_dependency 'bundler', '~> 1.14'
  s.add_runtime_dependency 'rubocop', '~> 0.52'
  s.add_runtime_dependency 'eventmachine', '~> 1.2', '>= 1.2.5'
  s.add_runtime_dependency 'reverse_markdown', '~> 1.0', '>= 1.0.5'
  s.add_runtime_dependency 'redcarpet', '~> 3.2', '>= 3.2.3'
  s.add_runtime_dependency 'htmlentities', '~> 4.3', '>= 4.3.4'
  s.add_runtime_dependency 'coderay', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 3.5', '>= 3.5.0'
  s.add_development_dependency 'rack-test', '~> 0.7'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'debase', '~> 0.2'
  s.add_development_dependency 'ruby-debug-ide', '~> 0.6'
end
