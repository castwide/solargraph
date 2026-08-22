# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::YardMap::Mapper::ToStructInitializer do
  around do |example|
    YARD::Registry.clear
    example.run
    YARD::Registry.clear
  end

  # Maps a source string the way a gem's yardoc would arrive: YARD parses it,
  # and the Mapper converts the resulting code objects into pins.
  #
  # @param code [String]
  # @return [Array<Solargraph::Pin::Base>]
  def map code
    YARD.parse_string(code)
    Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
  end

  # @param pins [Array<Solargraph::Pin::Base>]
  # @param path [String]
  # @return [Array<Solargraph::Pin::Base>]
  def pins_at pins, path
    pins.select { |pin| pin.path == path }
  end

  # Maps a source string from a real file on disk, the way a gem's yardoc
  # would -- needed for the `keyword_init: true` heuristic, which rereads
  # the source file and has nothing to read from `YARD.parse_string`'s
  # synthetic "(stdin)" object.
  #
  # @param code [String]
  # @return [Array<Solargraph::Pin::Base>]
  def map_file code
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'struct_def.rb')
      File.write(path, code)
      YARD.parse(path)
      Solargraph::YardMap::Mapper.new(YARD::Registry.all).map
    end
  end

  it 'synthesizes a .new and #initialize pin for a const-assigned Struct' do
    pins = map(<<~RUBY)
      Foo = Struct.new(:bar, :baz) do
        def combined
          "\#{bar}\#{baz}"
        end
      end
    RUBY

    new_pin = pins_at(pins, 'Foo.new').first
    init_pin = pins_at(pins, 'Foo#initialize').first
    expect(new_pin).to be_a(Solargraph::Pin::Method)
    expect(init_pin).to be_a(Solargraph::Pin::Method)
    expect(new_pin.parameters.map(&:name)).to eq(%w[bar baz])
    expect(init_pin.parameters.map(&:name)).to eq(%w[bar baz])
    expect(init_pin.visibility).to be(:private)
  end

  it 'gives struct members positional (arg) parameters by default' do
    pins = map('Foo = Struct.new(:bar, :baz)')
    init_pin = pins_at(pins, 'Foo#initialize').first
    expect(init_pin.parameters.map(&:decl)).to eq(%i[arg arg])
  end

  it 'gives struct members keyword parameters when keyword_init: true is used' do
    pins = map_file('Foo = Struct.new(:bar, :baz, keyword_init: true)')
    init_pin = pins_at(pins, 'Foo#initialize').first
    expect(init_pin.parameters.map(&:decl)).to eq(%i[kwoptarg kwoptarg])
  end

  it 'resolves .new against the real field list rather than Struct.new' do
    pins = map('Foo = Struct.new(:bar, :baz)')
    api_map = Solargraph::ApiMap.new(pins: pins)
    stack = api_map.get_method_stack('Foo', 'new', scope: :class)
    expect(stack.first.parameters.map(&:name)).to eq(%w[bar baz])
  end

  it 'handles the inheritance form (class Foo < Struct.new(...))' do
    pins = map(<<~RUBY)
      class Foo < Struct.new(:bar, :baz)
        def combined
          "\#{bar}\#{baz}"
        end
      end
    RUBY

    init_pin = pins_at(pins, 'Foo#initialize').first
    expect(init_pin).to be_a(Solargraph::Pin::Method)
    expect(init_pin.parameters.map(&:name)).to eq(%w[bar baz])
  end

  it 'does not synthesize a constructor for a plain constant' do
    pins = map('Foo = 42')
    expect(pins_at(pins, 'Foo.new')).to be_empty
    expect(pins_at(pins, 'Foo#initialize')).to be_empty
  end

  it 'honors a magic encoding comment when rereading the definition line' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'struct_def.rb')
      # File.readlines defaults to Encoding.default_external (UTF-8) and
      # does not itself honor a magic encoding comment the way compiling
      # the file would -- \xE9 is only valid as "e" line data under
      # ISO-8859-1. YARD parses this fine (it resolves the same comment),
      # so #keyword_init? has to detect and honor it too, not just survive
      # not honoring it.
      content = "# encoding: ISO-8859-1\nFoo = Struct.new(:bar, :baz, keyword_init: true) # caf\xE9\n"
      File.binwrite(path, content)
      YARD.parse(path)
      pins = Solargraph::YardMap::Mapper.new(YARD::Registry.all).map

      init_pin = pins_at(pins, 'Foo#initialize').first
      expect(init_pin.parameters.map(&:decl)).to eq(%i[kwoptarg kwoptarg])
    end
  end

  it 'falls back to positional when the declared encoding does not match the actual bytes' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'struct_def.rb')
      # The comment claims US-ASCII, but \xE9 is not a valid US-ASCII byte --
      # a genuinely unrecoverable case, not merely one File.readlines
      # defaults its way past. Exercised directly against #keyword_init?,
      # since a file this malformed is unlikely to reach YARD as a real
      # ClassObject in the first place.
      content = "# encoding: US-ASCII\nFoo = Struct.new(:bar, :baz, keyword_init: true) # caf\xE9\n"
      File.binwrite(path, content)

      code_object = Struct.new(:file, :line).new(path, 2)
      result = described_class.send(:keyword_init?, code_object, nil)
      expect(result).to be(false)
    end
  end

  it 'does not override an explicitly documented initialize' do
    pins = map(<<~RUBY)
      Foo = Struct.new(:bar) do
        def initialize(bar, extra)
          super(bar)
          @extra = extra
        end
      end
    RUBY

    init_pins = pins_at(pins, 'Foo#initialize')
    expect(init_pins.length).to eq(1)
    expect(init_pins.first.parameters.map(&:name)).to eq(%w[bar extra])
  end
end
