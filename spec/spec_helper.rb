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
