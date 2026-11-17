# frozen_string_literal: true

describe Solargraph::Collection::Base do
  let(:pin) { Solargraph::Pin::Namespace.new(name: 'Example', type: :class) }

  let(:klass) do
    Class.new(described_class) do
      attr_accessor :pins

      def cache_file
        File.join Solargraph::CacheDir.base_dir, 'example.ser'
      end
    end
  end

  let(:base) { klass.new }

  # Collection::Base memoizes in Collection.mem_cache, so the file has to be
  # the only source left for the load below to be proving anything.
  before { Solargraph::Collection.clear_mem_cache }

  it 'saves caches' do
    base.pins = [pin]
    base.load
    expect(File).to be_file(base.cache_file)
  end

  it 'loads from caches' do
    base.pins = []
    cache = base.load
    expect(cache).to eq([pin])
  end

  context 'with an invalid cache file' do
    before { FileUtils.mkdir_p File.dirname(base.cache_file) }

    after { klass.uncache }

    it 'raises when the file does not hold an array' do
      File.write base.cache_file, Marshal.dump('not an array'), mode: 'wb'
      expect { base.load }.to raise_error(TypeError, /does not contain an array of pins/)
    end

    it 'raises when the file holds a non-pin' do
      File.write base.cache_file, Marshal.dump([pin, 'not a pin']), mode: 'wb'
      expect { base.load }.to raise_error(TypeError, /contains a non-pin/)
    end

    it 'raises when the file is corrupt' do
      File.write base.cache_file, 'garbage', mode: 'wb'
      expect { base.load }.to raise_error(TypeError)
    end
  end

  it 'deletes caches' do
    klass.uncache
    expect(File).not_to be_file(base.cache_file)
  end
end
