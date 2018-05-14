require 'rake'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -I lib -r solargraph.rb"
end