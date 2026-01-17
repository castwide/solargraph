require 'bundler/setup'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)
unless ENV['SIMPLECOV_DISABLED']
  # set up lcov reporting for undercover
  require 'simplecov'
  require 'undercover/simplecov_formatter'

  SimpleCov.start do
    cname = ENV.fetch('TEST_COVERAGE_COMMAND_NAME', 'ad-hoc')
    command_name cname
    new_dir = File.join('coverage', cname)
    coverage_dir new_dir

    add_filter(%r{^/spec/})
    add_filter('/Rakefile')
    # included via gemspec before we start, so can never be covered
    add_filter('lib/solargraph/version.rb')
    # off by default - feel free to set if you'd like undercover to
    # hold you to making a more thorough set of specs
    enable_coverage(:branch) if ENV['SOLARGRAPH_BRANCH_COVERAGE']
  end
end
RSpec.configure do |c|
  # Allow use of --only-failures with rspec, handy for local development
  c.example_status_persistence_file_path = 'rspec-examples.txt'
end
require 'solargraph'
# execute any logging blocks to make sure they don't blow up
Solargraph::Logging.logger.sev_threshold = Logger::DEBUG
# ...but still suppress logger output in specs (if possible)
if Solargraph::Logging.logger.respond_to?(:reopen) && !ENV.key?('SOLARGRAPH_LOG')
  Solargraph::Logging.logger.reopen(File::NULL)
end

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
