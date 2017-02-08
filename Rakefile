require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:stub_current) do |t|
  `#{File.dirname(__FILE__)}/bin/stub-current.rb`
end
task :default => :stub_current
