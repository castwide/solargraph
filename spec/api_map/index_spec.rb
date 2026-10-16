# frozen_string_literal: true

describe Solargraph::ApiMap::Index do
  subject(:output_pins) { described_class.new(input_pins).pins }

  describe '#map_overrides' do
    let(:foo_class) do
      Solargraph::Pin::Namespace.new(name: 'Foo')
    end

    let(:foo_initialize) do
      init = Solargraph::Pin::Method.new(name: 'initialize',
                                         scope: :instance,
                                         parameters: [],
                                         closure: foo_class)
      # no return type specified
      param = Solargraph::Pin::Parameter.new(name: 'bar',
                                             closure: init)
      init.parameters << param
      init
    end

    let(:foo_new) do
      init = Solargraph::Pin::Method.new(name: 'new',
                                         scope: :class,
                                         parameters: [],
                                         closure: foo_class)
      # no return type specified
      param = Solargraph::Pin::Parameter.new(name: 'bar',
                                             closure: init)
      init.parameters << param
      init
    end

    let(:foo_override) do
      Solargraph::Pin::Reference::Override.from_comment('Foo#initialize',
                                                        '@param [String] bar')
    end

    let(:input_pins) do
      [
        foo_initialize,
        foo_new,
        foo_override
      ]
    end

    it 'has a docstring to process on override' do
      expect(foo_override.docstring.tags).to be_empty
    end

    it 'overrides .new method' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo.new' }
      first_parameter = method_pin.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end

    it 'overrides #initialize method in signature' do
      method_pin = output_pins.find { |pin| pin.path == 'Foo#initialize' }
      first_parameter = method_pin.parameters.first
      expect(first_parameter.return_type.tag).to eq('String')
    end
  end

  describe Solargraph::ApiMap::Index::ArrayHash do
    it 'returns and stores an empty Array for a missing key' do
      hash = described_class.new
      value = hash['missing']

      expect(value).to eq([])
      expect(hash['missing']).to be(value)
    end

    it 'gives #[] a non-nil type in typechecking' do
      index_path = File.expand_path('../../lib/solargraph/api_map/index.rb', __dir__)
      code = <<~RUBY
        # @param hash [Solargraph::ApiMap::Index::ArrayHash{String => Array<Integer>}]
        # @return [Array<Integer>]
        def lookup hash
          hash['key']
        end
      RUBY
      source_maps = [
        Solargraph::SourceMap.map(Solargraph::Source.load(index_path)),
        Solargraph::SourceMap.map(Solargraph::Source.load_string(code, 'test.rb'))
      ]
      api_map = Solargraph::ApiMap.new
      api_map.catalog Solargraph::Bench.new(source_maps: source_maps)
      checker = Solargraph::TypeChecker.new('test.rb', api_map: api_map, level: :strong)

      expect(checker.problems.map(&:message)).to be_empty
    end
  end
end
