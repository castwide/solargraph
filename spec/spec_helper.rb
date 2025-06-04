require 'bundler/setup'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
unless ENV['SIMPLECOV_DISABLED']
  require 'simplecov'
  SimpleCov.start
end
require 'solargraph'
# Suppress logger output in specs (if possible)
Solargraph::Logging.logger.reopen(File::NULL) if Solargraph::Logging.logger.respond_to?(:reopen)

def with_env_var(name, value)
  old_value = ENV[name]  # Store the old value
  ENV[name] = value      # Set to new value

  begin
    yield               # Execute the block
  ensure
    ENV[name] = old_value  # Restore the old value
  end
end
