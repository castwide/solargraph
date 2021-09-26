require 'bundler/setup'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
unless ENV['SIMPLECOV_DISABLED']
  require 'simplecov'
  SimpleCov.start unless ENV['SIMPLECOV_DISABLED']
end
require 'solargraph'
# Suppress logger output in specs (if possible)
Solargraph::Logging.logger.reopen(File::NULL) if Solargraph::Logging.logger.respond_to?(:reopen)
