# frozen_string_literal: true

describe Solargraph::Pin::Base do
  let(:zero_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:one_location) { Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0)) }

  it 'does not combine pins with directive changes' do
    pin1 = described_class.new(location: zero_location, name: 'Foo', comments: 'A Foo class',
                               source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    pin2 = described_class.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro',
                               source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    expect(pin1.nearly?(pin2)).to be(false)
    # enable asserts
    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :macros count/)
    end
  end

  it 'does not combine pins with different directives' do
    pin1 = described_class.new(location: zero_location, name: 'Foo', comments: '@!macro my_macro',
                               source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    pin2 = described_class.new(location: zero_location, name: 'Foo', comments: '@!macro other',
                               source: :yardoc, closure: Solargraph::Pin::ROOT_PIN)
    expect(pin1.nearly?(pin2)).to be(false)
    with_env_var('SOLARGRAPH_ASSERTS', 'on') do
      expect { pin1.combine_with(pin2) }.to raise_error(RuntimeError, /Inconsistent :macros values/)
    end
  end

  it 'sees tag differences as not near or equal' do
    pin1 = described_class.new(location: zero_location, name: 'Foo', comments: '@return [Foo]')
    pin2 = described_class.new(location: zero_location, name: 'Foo', comments: '@return [Bar]')
    expect(pin1.nearly?(pin2)).to be(false)
    expect(pin1 == pin2).to be(false)
  end

  it 'sees comment differences as nearly but not equal' do
    pin1 = described_class.new(location: zero_location, name: 'Foo', comments: 'A Foo class')
    pin2 = described_class.new(location: zero_location, name: 'Foo', comments: 'A different Foo')
    expect(pin1.nearly?(pin2)).to be(true)
    expect(pin1 == pin2).to be(false)
  end

  it 'recognizes deprecated tags' do
    pin = described_class.new(location: zero_location, name: 'Foo', comments: '@deprecated Use Bar instead.')
    expect(pin).to be_deprecated
  end

  it 'does not link documentation for undefined return types' do
    pin = described_class.new(name: 'Foo', comments: '@return [undefined]')
    expect(pin.link_documentation).to eq('Foo')
  end

  it 'deals well with known closure combination issue' do
    Solargraph::Shell.new.uncache('yard')
    api_map = Solargraph::ApiMap.load_with_cache('.', $stderr)
    pins = api_map.get_method_stack('YARD::Docstring', 'parser', scope: :class)
    expect(pins.length).to eq(1)
    parser_method_pin = pins.first
    return_type = parser_method_pin.typify(api_map)
    expect(parser_method_pin.closure.name).to eq('Docstring')
    expect(parser_method_pin.closure.gates).to eq(['YARD::Docstring', 'YARD', ''])
    expect(return_type).to be_defined
    expect(parser_method_pin.typify(api_map).rooted_tags).to eq('::YARD::DocstringParser')
  end

  describe '#typify' do
    it 'resolves RBS type aliases' do
      skip 'This test fails on CI but not locally'
      api_map = Solargraph::ApiMap.load_with_cache('.', $stderr)
      pin = api_map.get_path_pins('RBS::MethodType#type').first
      expect(pin.typify(api_map).to_s).to eq('RBS::Types::Function, RBS::Types::UntypedFunction')
    end
  end

  describe '#macro_names' do
    it 'returns names' do
      pin = described_class.new(name: 'Example', comments: "@macro addcomment\n@macro returnself")
      expect(pin.macro_names).to eq(['addcomment', 'returnself'])
    end
  end

  describe '#nearly?' do
    it 'avoids recursion when two pins have the same closure' do
      pin1 = Solargraph::Pin::Base.new(name: 'foo')
      pin1.closure = pin1
      pin2 = Solargraph::Pin::Base.new(name: 'foo', closure: pin1)
      expect { pin1.nearly?(pin2) }.not_to raise_error
    end
  end

  describe '#type_desc' do
    # @param tag [String]
    # @return [String, nil]
    def desc_of tag
      Solargraph::Pin::ProxyType.new(name: 'foo', return_type: Solargraph::ComplexType.parse(tag)).type_desc
    end

    it 'keeps the parameter of a class object inside an intersection' do
      expect(desc_of('Class<Foo> & Comparable')).to eq('Class<Foo> & Comparable')
    end

    it 'keeps the parameter of a module object, which RBS cannot write either' do
      expect(desc_of('Module<Foo>')).to eq('Module<Foo>')
    end

    it 'keeps the parameter of a class object that is not the first union member' do
      expect(desc_of('String, Class<Foo>')).to eq('String, Class<Foo>')
    end

    it 'keeps the parameter of a lone class object' do
      expect(desc_of('Class<Foo>')).to eq('Class<Foo>')
    end

    it 'prefers RBS for a type RBS can write, even where the tag reads differently' do
      expect(desc_of('Array<String>')).to eq('Array[String]')
    end

    it 'prefers RBS for a bare Class, which names no instance to lose' do
      pin = Solargraph::Pin::Method.new(name: 'foo', comments: '@return [Class]', scope: :instance,
                                        closure: Solargraph::Pin::Namespace.new(name: 'Bar'))
      expect(pin.type_desc).to eq('Bar#foo def foo: () -> Class')
    end

    it 'prefers RBS when the return type is a UniqueType rather than a ComplexType' do
      pin = Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.parse('Array<String>').items.first)
      expect(pin.return_type).to be_a(Solargraph::ComplexType::UniqueType)
      expect(pin.type_desc).to eq('Array[String]')
    end
  end
end
