require 'bundler/setup'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
unless ENV['SIMPLECOV_DISABLED']
  # set up lcov reporting for undercover
  require 'simplecov'
  require 'simplecov-lcov'
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov.start do
    add_filter(%r{^/spec/})
    add_filter('/Rakefile')
    # off by default - feel free to set if you'd like undercover to
    # hold you to a thorough set of specs
    enable_coverage(:branch) if ENV['SOLARGRAPH_BRANCH_COVERAGE']
  end
end
RSpec.configure do |c|
  # Allow use of --only-failures with rspec, handy for local development
  c.example_status_persistence_file_path = 'rspec-examples.txt'
end
require 'solargraph'
# Suppress logger output in specs (if possible)
Solargraph::Logging.logger.reopen(File::NULL) if Solargraph::Logging.logger.respond_to?(:reopen)

# @param name [String]
# @param value [String]
def with_env_var(name, value)
  old_value = ENV[name]  # Store the old value
  ENV[name] = value      # Set to new value

  begin
    yield               # Execute the block
  ensure
    ENV[name] = old_value  # Restore the old value
  end
end
