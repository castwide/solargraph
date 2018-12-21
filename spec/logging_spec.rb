require 'tempfile'

describe Solargraph::Logging do
  it "logs messages with levels" do
    # @todo Logger#reopen is only available in Ruby 2.3+. This is a quick and
    #   dirty hack to avoid erroneous failures in Travis.
    next if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3.0')
    file = Tempfile.new('log')
    Solargraph::Logging.logger.reopen file
    Solargraph::Logging.logger.warn "Test"
    file.rewind
    msg = file.read
    file.close
    file.unlink
    Solargraph::Logging.logger.reopen STDERR
    expect(msg).to include('WARN')
  end
end
