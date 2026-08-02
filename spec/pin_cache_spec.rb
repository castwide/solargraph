# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::PinCache do
  describe '.save' do
    # Writing straight to the final path (the old behavior) means any
    # other process reading or writing that same path concurrently -
    # e.g. multiple parallel_tests workers, each a separate OS process,
    # racing to cache the same not-yet-cached gem for the first time -
    # can observe a truncated or torn file. Writing to a temp file and
    # renaming into place is atomic on the same filesystem, so readers
    # always see either the complete old file or the complete new one.
    it 'writes to a temp file and renames it into place, never writing the target path directly' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'gem.ser')
        pins = [Solargraph::Pin::Base.new(name: 'foo')]

        written_path = nil
        renamed_from = nil
        renamed_to = nil
        allow(File).to receive(:write).and_wrap_original do |original, path, *args, **kwargs|
          written_path = path
          original.call(path, *args, **kwargs)
        end
        allow(File).to receive(:rename).and_wrap_original do |original, from, to|
          renamed_from = from
          renamed_to = to
          original.call(from, to)
        end

        described_class.send(:save, file, pins)

        expect(written_path).not_to eq(file), 'save wrote directly to the target path instead of a temp file'
        expect(renamed_from).to eq(written_path)
        expect(renamed_to).to eq(file)
      end
    end

    it 'does not leave temp files behind' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'single.ser')
        described_class.send(:save, file, [Solargraph::Pin::Base.new(name: 'foo')])
        expect(Dir.glob("#{file}*")).to eq([file])
      end
    end

    it 'round-trips pins through save and load' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'roundtrip.ser')
        pins = [Solargraph::Pin::Base.new(name: 'foo'), Solargraph::Pin::Base.new(name: 'bar')]
        described_class.send(:save, file, pins)
        expect(described_class.send(:load, file).map(&:name)).to eq(%w[foo bar])
      end
    end
  end
end
