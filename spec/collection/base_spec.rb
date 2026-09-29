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

  it 'deletes caches' do
    klass.uncache
    expect(File).not_to be_file(base.cache_file)
  end
end
