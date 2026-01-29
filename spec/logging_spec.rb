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
    Solargraph::Logging.logger.reopen File::NULL
    expect(msg).to include('WARN')
  end
end
