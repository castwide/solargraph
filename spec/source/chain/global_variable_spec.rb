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

  # Pins from an RBS signature outside core, like a gem signature
  #
  # @param rbs [String]
  # @return [Array<Solargraph::Pin::Base>]
  def non_core_rbs_pins rbs
    require 'tmpdir'
    Dir.mktmpdir('rspec-solargraph-') do |dir|
      File.write(File.join(dir, 'globals.rbs'), rbs)
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: RBS::Repository.new(no_stdlib: true))
      loader.add(path: Pathname(dir))
      Solargraph::RbsMap::Conversions.new(loader: loader).pins
    end
  end

  it 'keeps the core RBS type of a global that gem source assigns a subtype' do
    gem_map = Solargraph::SourceMap.load_string(%(
      def silence
        $stderr = File.new(File::NULL, 'w')
      end
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins
    expect(infer_global('$stderr', api_map).rooted_tags).to eq('::IO')
  end

  it 'keeps the core RBS type of a global that gem-source YARD declares as another type' do
    gem_map = Solargraph::SourceMap.load_string(%(
      # @type [StringIO]
      $stderr = StringIO.new
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins
    expect(infer_global('$stderr', api_map).rooted_tags).to eq('::IO')
  end

  it 'keeps the core RBS type of a global that non-core RBS declares as another type' do
    rbs_pins = non_core_rbs_pins('$stderr: StringIO')
    api_map = Solargraph::ApiMap.new
    api_map.index rbs_pins
    expect(infer_global('$stderr', api_map).rooted_tags).to eq('::IO')
  end

  it 'unions the types that non-core RBS and gem-source YARD declare for a global' do
    rbs_pins = non_core_rbs_pins('$gem_global: Integer')
    gem_map = Solargraph::SourceMap.load_string(%(
      # @type [String]
      $gem_global = 'x'
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins + rbs_pins
    expect(infer_global('$gem_global', api_map).items.map(&:rooted_tag)).to contain_exactly('::Integer', '::String')
  end

  it 'prefers a type that gem-source YARD declares over a non-core RBS untyped declaration' do
    rbs_pins = non_core_rbs_pins('$untyped_global: untyped')
    gem_map = Solargraph::SourceMap.load_string(%(
      # @type [String]
      $untyped_global = 'x'
    ), '/gems/some_gem/lib/some_gem.rb')
    api_map = Solargraph::ApiMap.new
    api_map.index gem_map.pins + rbs_pins
    expect(infer_global('$untyped_global', api_map).rooted_tags).to eq('::String')
  end

  it 'keeps the core RBS type of a global that the workspace assigns a subtype' do
    source = Solargraph::Source.load_string(%(
      $stderr = File.new(File::NULL, 'w')
      $stderr
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [2, 8]).infer.rooted_tags).to eq('::IO')
  end

  it 'prefers a workspace YARD declaration over workspace assignments' do
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

  it 'infers a global from its assignments when its only declaration is a YARD untyped tag' do
    source = Solargraph::Source.load_string(%(
      # @type [untyped]
      $untyped_global = 'x'
      $untyped_global = 1
      $untyped_global
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    expect(api_map.clip_at('test.rb', [4, 8]).infer.rooted_tags).to eq('::String, ::Integer')
  end

  it 'defines a global declared in core RBS at its workspace assignments too' do
    source = Solargraph::Source.load_string(%(
      $stderr = File.new(File::NULL, 'w')
      $stderr
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    lines = api_map.clip_at('test.rb', [2, 8]).define.filter_map(&:location).map { |location| location.range.start.line }
    expect(lines).to include(1)
  end
end
