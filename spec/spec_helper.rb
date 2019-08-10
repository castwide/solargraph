$LOAD_PATH.unshift File.realpath(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
require 'simplecov'
SimpleCov.start
require 'solargraph'
# Suppress logger output in specs (if possible)
Solargraph::Logging.logger.reopen(File::NULL) if Solargraph::Logging.logger.respond_to?(:reopen)
