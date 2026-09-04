# frozen_string_literal: true

require 'tempfile'

describe Solargraph::Logging do
  it 'gives a class overriding log_level its own logger at that level, leaving the shared one alone' do
    logging = described_class
    verbose_class = Class.new do
      include logging

      def log_level
        :debug
      end

      # module_function makes #logger private on includers.
      def build_logger
        logger
      end
    end

    built = verbose_class.new.build_logger

    expect(built.level).to eq(Logger::DEBUG)
    expect(built).not_to be(described_class.logger)
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

  describe '.resolve_level' do
    it 'resolves a recognized level with no warning' do
      expect { @level = described_class.resolve_level('debug') }.not_to output.to_stderr

      expect(@level).to eq(Logger::DEBUG)
    end

    it 'warns and falls back to the default level for an unrecognized value' do
      level = nil
      output = capture_both { level = described_class.resolve_level('bogus') }

      expect(output).to include('Invalid value for SOLARGRAPH_LOG: "bogus"')
      expect(level).to eq(Logger::WARN)
    end

    it 'falls back to the default level with no warning when unset' do
      expect { @level = described_class.resolve_level(nil) }.not_to output.to_stderr

      expect(@level).to eq(Logger::WARN)
    end
  end
end
