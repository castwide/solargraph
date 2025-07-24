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
    enable_coverage(:branch)
  end
end
require 'solargraph'
# execute any logging blocks to make sure they don't blow up
Solargraph::Logging.logger.sev_threshold = Logger::DEBUG
# ...but still suppress logger output in specs (if possible)
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

def capture_stdout &block
  original_stdout = $stdout
  $stdout = StringIO.new
  begin
    block.call
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end

def capture_both &block
  original_stdout = $stdout
  original_stderr = $stderr
  stringio = StringIO.new
  $stdout = stringio
  $stderr = stringio
  begin
    block.call
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
  stringio.string
end
