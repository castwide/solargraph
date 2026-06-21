# frozen_string_literal: true

describe Solargraph::Typedef::Path do
  describe '.new' do
    it 'assumes not rooted' do
      path = described_class.new('Foo')
      expect(path).not_to be_rooted
    end

    it 'accepts rooted' do
      path = described_class.new('Foo', rooted: true)
      expect(path).to be_rooted
    end

    it 'sets rooted from explicit root path' do
      path = described_class.new('::Foo')
      expect(path).to be_rooted
    end

    it 'sets root' do
      path = described_class.new('')
      expect(path).to be_root
    end

    it 'converts core pin paths' do
      api_map = Solargraph::ApiMap.new
      api_map.pins.each { |pin| pin.typedef_path }
    end
  end

  describe '#from' do
    it 'combines paths' do
      path1 = described_class.new('Bar')
      path2 = described_class.new('Foo')
      joined = path1.from(path2)
      expect(joined.name).to eq('Foo::Bar')
    end

    it 'sets rooted' do
      path1 = described_class.new('Bar')
      path2 = described_class.new('::Foo')
      joined = path1.from(path2)
      expect(joined.name).to eq('Foo::Bar')
      expect(joined).to be_rooted
    end
  end

  describe '#resolve_rooted' do
    it 'returns rooted paths' do
      source = Solargraph::Source.load_string(%(
        class Foo
          class Bar
          end
        end
      ))
      api_map = Solargraph::ApiMap.new.map(source)
      path = described_class.new('Bar')
      resolved = path.resolve_rooted(api_map, ['Foo', ''])
      expect(resolved.name).to eq('Foo::Bar')
      expect(resolved).to be_rooted
    end
  end
end
