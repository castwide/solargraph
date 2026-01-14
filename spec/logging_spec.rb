# frozen_string_literal: true

require 'tempfile'

describe Solargraph::Logging do
  it 'logs messages with levels' do
    file = Tempfile.new('log')
    described_class.logger.reopen file
    described_class.logger.warn 'Test'
    file.rewind
    msg = file.read
    file.close
    file.unlink
    described_class.logger.reopen $stderr
    expect(msg).to include('WARN')
  end
end
