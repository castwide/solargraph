# frozen_string_literal: true

require 'tempfile'

describe Solargraph::Logging do
  it 'warns and falls back to the default level for an invalid SOLARGRAPH_LOG value' do
    # The invalid-value check runs once, at module load time, so a normal
    # spec calling described_class.logger cannot re-trigger it in-process.
    lib_dir = File.expand_path('../lib', __dir__)
    # @sg-ignore Kernel#` is untyped for an xstr node - no upstream issue filed yet
    output = `SOLARGRAPH_LOG=bogus bundle exec ruby -I#{lib_dir} -e "require 'solargraph/logging'" 2>&1`

    expect(output).to include('Invalid value for SOLARGRAPH_LOG: "bogus"')
    expect(output).to include('valid values are')
  end

  it 'logs messages with levels' do
    file = Tempfile.new('log')
    described_class.logger.reopen file
    described_class.logger.warn 'Test'
    file.rewind
    msg = file.read
    file.close
    file.unlink
    described_class.logger.reopen File::NULL
    expect(msg).to include('WARN')
  end
end
