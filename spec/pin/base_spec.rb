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

  describe '#realize' do
    it 'roots an already-defined but unrooted return type' do
      api_map = Solargraph::ApiMap.new
      pin = Solargraph::Pin::Method.new(name: 'bar', comments: '@return [String]')
      expect(pin.return_type).to be_defined
      expect(pin.return_type.all_rooted?).to be(false)
      realized = pin.realize(api_map)
      expect(realized.return_type.all_rooted?).to be(true)
      expect(realized.return_type.rooted_tags).to eq('::String')
    end

    it 'keeps a correctly-synced docstring on the already-rooted fast path' do
      return_type = Solargraph::ComplexType.try_parse('String').force_rooted
      pin = Solargraph::Pin::Method.new(name: 'bar', return_type: return_type)
      realized = pin.realize(Solargraph::ApiMap.new)
      expect(realized).to equal(pin) # fast path: proxy is never called
      expect(realized.docstring.tag(:return)&.types).to eq(['::String'])
      expect(realized.documentation).to include('Returns:')
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

  describe '#reset_generated!' do
    it 'discards a memoized documentation string on a pin class that is not a method' do
      pin = Solargraph::Pin::Constant.new(name: 'BAZ', closure: Solargraph::Pin::ROOT_PIN, source: :rbs,
                                          comments: 'Original description.')
      expect(pin.documentation).to include('Original description.')
      pin.instance_variable_set(:@comments, 'Changed description.')
      pin.instance_variable_set(:@docstring, nil)
      pin.reset_generated!
      expect(pin.documentation).to include('Changed description.')
    end
  end

  describe 'combining with an authoritative pin' do
    let(:closure) { Solargraph::Pin::Namespace.new(name: 'Foo') }

    let(:base) do
      Solargraph::Pin::Method.new(name: 'bar', closure: closure,
                                  comments: "Original prose.\n@param baz [Integer]\n@return [Integer]")
    end

    let(:boss) do
      Solargraph::Pin::Method.new(name: 'bar', closure: closure,
                                  comments: '@return [String]', combine_priority: 1)
    end

    it 'replaces only the tags the authoritative pin supplies' do
      combined = base.combine_with(boss)
      expect(combined.docstring.tag(:return).types).to eq(['String'])
      expect(combined.docstring.tag(:param).name).to eq('baz')
    end

    it 'keeps comments and docstring describing the same thing' do
      combined = base.combine_with(boss)
      expect(combined.comments).to eq("#{combined.docstring.to_raw}\n")
    end

    it 'wins from either side of the combine' do
      expect(boss.combine_with(base).docstring.tag(:return).types).to eq(['String'])
    end

    it 'prefers the higher priority when both pins declare one' do
      lower = Solargraph::Pin::Method.new(name: 'bar', closure: closure,
                                          comments: '@return [Integer]', combine_priority: 1)
      higher = Solargraph::Pin::Method.new(name: 'bar', closure: closure,
                                           comments: '@return [String]', combine_priority: 2)
      expect(lower.combine_with(higher).docstring.tag(:return).types).to eq(['String'])
    end

    it 'merges by the ordinary rules when neither pin has priority' do
      plain = Solargraph::Pin::Method.new(name: 'bar', closure: closure, comments: '@return [String]')
      expect(base.combine_with(plain).docstring.tag(:param).name).to eq('baz')
    end
  end

  describe '#parse_comments' do
    it 'keeps a docstring supplied at construction when there are no comments to reparse' do
      docstring = Solargraph::Source.parse_docstring('@param x [String] the x').to_docstring
      pin = Solargraph::Pin::Method.new(name: 'initialize', closure: Solargraph::Pin::ROOT_PIN,
                                        docstring: docstring, comments: '')
      expect(pin.directives).to be_empty
      expect(pin.docstring.tags(:param).map(&:name)).to eq(['x'])
    end
  end
end
