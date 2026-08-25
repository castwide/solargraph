require 'tempfile'

describe Solargraph::Logging do
  it "logs messages with levels" do
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

  it 'caches the custom logger for an overridden log_level' do
    klass = Class.new do
      include Solargraph::Logging

      def log_level
        :debug
      end
    end
    instance = klass.new
    expect(instance.send(:logger)).to equal(instance.send(:logger))
  end
end
