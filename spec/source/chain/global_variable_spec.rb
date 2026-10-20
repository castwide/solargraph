# frozen_string_literal: true

describe Solargraph::Source::Chain::GlobalVariable do
  it 'resolves instance variable pins' do
    closure = Solargraph::Pin::Namespace.new(name: 'Foo')
    foo_pin = Solargraph::Pin::GlobalVariable.new(closure: closure, name: '$foo')
    not_pin = Solargraph::Pin::InstanceVariable.new(closure: closure, name: '@bar')
    api_map = Solargraph::ApiMap.new
    api_map.index [foo_pin, not_pin]
    link = described_class.new('$foo')
    pins = link.resolve(api_map, Solargraph::ComplexType.parse('Foo'), [])
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('$foo')
  end

  # @param name [String]
  # @param api_map [Solargraph::ApiMap]
  # @return [Solargraph::ComplexType]
  def infer_global name, api_map
    Solargraph::Source::Chain.new([described_class.new(name)]).infer(api_map, Solargraph::Pin::ROOT_PIN, [])
  end

  it 'keeps the RBS type of a global that gem source assigns an unknown value' do
    gem_map = Solargraph::SourceMap.load_string(%(
      def silence
        $stderr = StringIO.new
      end
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins
    expect(infer_global('$stderr', api_map).rooted_tags).to eq('::IO')
  end

  it 'keeps the RBS type of a global that gem source declares as another type' do
    gem_map = Solargraph::SourceMap.load_string(%(
      # @type [StringIO]
      $stderr = StringIO.new
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins
    expect(infer_global('$stderr', api_map).rooted_tags).to eq('::IO')
  end

  it 'keeps an RBS untyped declaration untyped when gem source declares a type' do
    require 'tmpdir'
    rbs_pins = Dir.mktmpdir('rspec-solargraph-') do |dir|
      File.write(File.join(dir, 'globals.rbs'), '$untyped_global: untyped')
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: true))
      loader.add(path: Pathname(dir))
      Solargraph::RbsMap::Conversions.new(loader: loader).pins
    end
    gem_map = Solargraph::SourceMap.load_string(%(
      # @type [String]
      $untyped_global = 'x'
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins + rbs_pins
    expect(infer_global('$untyped_global', api_map)).to be_undefined
  end

  it 'keeps the RBS type of a global that the workspace assigns a narrower value' do
    source = Solargraph::Source.load_string(%(
      $stderr = StringIO.new
      $stderr
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [2, 8]).infer.rooted_tags).to eq('::IO')
  end

  it 'prefers a workspace declaration over workspace assignments' do
    source = Solargraph::Source.load_string(%(
      # @type [Numeric]
      $my_global = 1
      $my_global = 'x'
      $my_global
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 8]).infer.rooted_tags).to eq('::Numeric')
  end

  it 'unions the assignments of an undeclared global' do
    source = Solargraph::Source.load_string(%(
      $my_global = 1
      $my_global = 'x'
      $my_global
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [3, 8]).infer.rooted_tags).to eq('::Integer, ::String')
  end
end
