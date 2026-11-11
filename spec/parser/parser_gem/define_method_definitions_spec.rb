describe Solargraph::Parser::ParserGem::NodeProcessors::DefineMethodDefinitions do
  # @param code [String]
  # @return [Solargraph::ApiMap]
  def map_code code
    map = Solargraph::ApiMap.new
    map.map Solargraph::Source.load_string(code, 'test.rb')
    map
  end

  it 'generates instance methods from a splat parameter iterated with each' do
    map = map_code(%(
      class Base
        def self.add_flash_types(*types)
          types.each do |type|
            define_method(type) { request.flash[type] }
          end
        end
        add_flash_types :alert, 'notice'
      end
    ))
    expect(map.get_path_pins('Base#alert').first).to be_a(Solargraph::Pin::Method)
    expect(map.get_path_pins('Base#notice').first).to be_a(Solargraph::Pin::Method)
  end

  it 'generates methods in subclasses from an inherited class method' do
    map = map_code(%(
      class Base
        def self.add_flash_types(*types)
          types.each { |type| define_method(type) { type } }
        end
      end
      class ApplicationController < Base
        add_flash_types :success, :error
      end
    ))
    expect(map.get_path_pins('ApplicationController#success')).not_to be_empty
    expect(map.get_path_pins('ApplicationController#error')).not_to be_empty
    expect(map.get_path_pins('Base#success')).to be_empty
  end

  it 'generates methods from a parameter passed directly' do
    map = map_code(%(
      class Base
        def self.flag(name, default = false)
          define_method(name) { default }
        end
        flag :enabled, true
      end
    ))
    expect(map.get_path_pins('Base#enabled')).not_to be_empty
    expect(map.get_path_pins('Base#true')).to be_empty
  end

  it 'generates methods from an array parameter iterated with each' do
    map = map_code(%(
      class Base
        def self.flags(names)
          names.each { |name| define_method(name) { true } }
        end
        flags [:a, :b]
      end
    ))
    expect(map.get_path_pins('Base#a')).not_to be_empty
    expect(map.get_path_pins('Base#b')).not_to be_empty
  end

  it 'generates class methods from define_singleton_method' do
    map = map_code(%(
      class Base
        def self.finder(name)
          define_singleton_method(name) { nil }
        end
        finder :lookup
      end
    ))
    expect(map.get_path_pins('Base.lookup')).not_to be_empty
    expect(map.get_path_pins('Base#lookup')).to be_empty
  end

  it 'accepts calls on self' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
        self.flag :enabled
      end
    ))
    expect(map.get_path_pins('Base#enabled')).not_to be_empty
  end

  it 'copies the parameters of the define_method block' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { |value, *rest, key: 1, &blk| value }
        end
        flag :enabled
      end
    ))
    pin = map.get_path_pins('Base#enabled').first
    params = pin.parameters.map { |param| [param.decl, param.name] }
    expect(params).to eq([[:arg, 'value'], [:restarg, 'rest'], [:kwoptarg, 'key'], [:blockarg, 'blk']])
  end

  it 'leaves the return type undefined' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
        flag :enabled
      end
    ))
    pin = map.get_path_pins('Base#enabled').first
    expect(pin.typify(map)).to be_undefined
  end

  it 'ignores arguments that are not literals' do
    map = map_code(%(
      NAME = :constant
      class Base
        def self.flag(*names)
          names.each { |name| define_method(name) { true } }
        end
        flag NAME, :literal, "inter\#{1}"
      end
    ))
    expect(map.get_path_pins('Base#literal')).not_to be_empty
    expect(map.get_path_pins('Base#constant')).to be_empty
    expect(map.get_path_pins('Base#NAME')).to be_empty
  end

  it 'ignores calls inside methods' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
        def self.setup
          flag :inside
        end
      end
    ))
    expect(map.get_path_pins('Base#inside')).to be_empty
  end

  it 'ignores methods whose define_method name is not a parameter' do
    map = map_code(%(
      class Base
        def self.flag(name)
          other = :fixed
          define_method(other) { true }
        end
        flag :enabled
      end
    ))
    expect(map.get_path_pins('Base#enabled')).to be_empty
  end

  it 'ignores calls to an unrelated method with the same name' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
      end
      class Other
        def self.flag(name); end
        flag :unrelated
      end
    ))
    expect(map.get_path_pins('Other#unrelated')).to be_empty
  end

  it 'generates methods from a call in a block at module level' do
    definer = Solargraph::SourceMap.load_string(%(
      module Flash
        module ClassMethods
          def add_flash_types(*types)
            types.each do |type|
              define_method(type) { type }
            end
          end
        end
      end
    ), 'definer.rb')
    call = Solargraph::SourceMap.load_string(%(
      module Flash
        included do
          add_flash_types(:alert, :notice)
        end
      end
      class Base
        include Flash
      end
    ), 'call.rb')
    map = Solargraph::ApiMap.new
    map.catalog Solargraph::Bench.new(source_maps: [definer, call])
    expect(map.get_path_pins('Flash#alert').first.location.filename).to eq('call.rb')
    expect(map.get_method_stack('Base', 'notice')).not_to be_empty
  end

  it 'gives methods defined without a literal block open parameters' do
    map = map_code(%(
      class Base
        def self.flag(name, &block)
          define_method(name, &block)
        end
        flag :enabled
      end
    ))
    pin = map.get_path_pins('Base#enabled').first
    expect(pin.parameters.map(&:decl)).to eq(%i[restarg kwrestarg blockarg])
  end

  it 'skips keyword arguments and stops at splatted arguments' do
    map = map_code(%(
      class Base
        def self.flags(*names, **options)
          names.each { |name| define_method(name) { options } }
        end
        def self.flag(name)
          define_method(name) { true }
        end
        flags :a, :b, option: true
        flags :c, *OTHERS, :d
        flag *OTHERS
        flags
      end
    ))
    expect(map.get_path_pins('Base#a')).not_to be_empty
    expect(map.get_path_pins('Base#b')).not_to be_empty
    expect(map.get_path_pins('Base#option')).to be_empty
    expect(map.get_path_pins('Base#c')).not_to be_empty
    expect(map.get_path_pins('Base#d')).to be_empty
  end

  it 'requires an array literal for an iterated array parameter' do
    map = map_code(%(
      class Base
        def self.flags(names)
          names.each { |name| define_method(name) { true } }
        end
        flags :single
      end
    ))
    expect(map.get_path_pins('Base#single')).to be_empty
  end

  it 'ignores calls in singleton class bodies' do
    map = map_code(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
        class << self
          flag :singleton
        end
      end
    ))
    expect(map.get_path_pins('Base#singleton')).to be_empty
    expect(map.get_path_pins('Base.singleton')).to be_empty
  end

  it 'keeps the summary when combined with a pin without a body' do
    source = Solargraph::SourceMap.load_string(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
      end
    ), 'test.rb')
    pin = source.pins.find { |p| p.path == 'Base.flag' }
    other = Solargraph::Pin::Method.new(name: 'flag', closure: pin.closure, scope: :class, source: :rbs)
    expect(other.combine_with(pin).call_site_templates).to eq(pin.call_site_templates)
    expect(pin.combine_with(other).call_site_templates).to eq(pin.call_site_templates)
  end

  it 'keeps the summary through serialization' do
    source = Solargraph::SourceMap.load_string(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
      end
    ), 'test.rb')
    pin = source.pins.find { |p| p.path == 'Base.flag' }
    copy = Marshal.load(Marshal.dump(pin))
    expect(copy.call_site_templates).to eq(pin.call_site_templates)
    expect(copy.call_site_templates).not_to be_empty
  end

  it 'keeps one summary per scope, position and mode' do
    map = map_code(%(
      class Base
        def self.flags(*types)
          types.each { |t| define_method(t) { nil } }
          types.each { |t| define_method(t) { |x| nil } }
          types.each { |t| define_method(t) { |y| nil } }
        end
        flags :a, :b
      end
    ))
    expect(map.get_path_pins('Base.flags').first.call_site_templates.length).to eq(1)
    expect(map.get_path_pins('Base#a').length).to eq(1)
    expect(map.get_path_pins('Base#b').length).to eq(1)
  end

  it 'generates one method per name in a call' do
    map = map_code(%(
      class Base
        def self.flags(*types)
          types.each { |t| define_method(t) { nil } }
        end
        flags :a, :a, 'a'
      end
    ))
    expect(map.get_path_pins('Base#a').length).to eq(1)
  end

  it 'ignores parameters past the positional limit' do
    params = (0..Solargraph::Parser::ParserGem::NodeProcessors::DefineMethodDefinitions::Template::MAX_POSITIONS).map { |i| "p#{i}" }
    map = map_code(%(
      class Base
        def self.flag(#{params.join(', ')})
          define_method(p0) { nil }
          define_method(#{params.last}) { nil }
        end
        flag #{params.map { |name| ":#{name}" }.join(', ')}
      end
    ))
    expect(map.get_path_pins('Base#p0')).not_to be_empty
    expect(map.get_path_pins("Base##{params.last}")).to be_empty
  end

  it 'ignores define_method calls past the block depth limit' do
    depth = Solargraph::Parser::ParserGem::NodeProcessors::DefineMethodDefinitions::Template::MAX_BLOCK_DEPTH
    map = map_code(%(
      class Base
        def self.shallow(name)
          #{'tap { ' * (depth - 1)}define_method(name) { nil }#{' }' * (depth - 1)}
        end
        def self.deep(name)
          #{'tap { ' * depth}define_method(name) { nil }#{' }' * depth}
        end
        shallow :near
        deep :far
      end
    ))
    expect(map.get_path_pins('Base#near')).not_to be_empty
    expect(map.get_path_pins('Base#far')).to be_empty
  end

  it 'examines each define_method call in a method once' do
    template = Solargraph::Parser::ParserGem::NodeProcessors::DefineMethodDefinitions::Template.singleton_class
    template_calls = lambda do |count|
      code = "class Base\n  def self.setup(unused)\n#{"    define_method(:m) { nil }\n" * count}  end\nend\n"
      calls = 0
      trace = TracePoint.new(:call) { |tp| calls += 1 if tp.defined_class == template }
      trace.enable { Solargraph::SourceMap.load_string(code, 'test.rb').pins }
      calls
    end
    expect(template_calls.call(200)).to be <= 2 * template_calls.call(100)
  end

  it 'keeps one copy of a template when combining a pin with its copy' do
    source = Solargraph::SourceMap.load_string(%(
      class Base
        def self.flag(name)
          define_method(name) { true }
        end
      end
    ), 'test.rb')
    pin = source.pins.find { |p| p.path == 'Base.flag' }
    copy = Marshal.load(Marshal.dump(pin))
    expect(pin.combine_with(copy).call_site_templates.length).to eq(1)
  end

  it 'reads a block variable that a parser wraps in procarg0' do
    # Parsers built with emit_procarg0 write |type| as s(:procarg0, s(:arg, :type))
    node = ->(type, *children) { Parser::AST::Node.new(type, children) }
    send = node.call(:send, nil, :define_method, node.call(:lvar, :type))
    block = node.call(:block, node.call(:send, node.call(:lvar, :types), :each),
                      node.call(:args, node.call(:procarg0, node.call(:arg, :type))), send)
    def_node = node.call(:defs, node.call(:self), :add, node.call(:args, node.call(:restarg, :types)), block)
    template = Solargraph::Parser::ParserGem::NodeProcessors::DefineMethodDefinitions::Template
               .from_send(send, def_node, [block])
    expect(template&.mode).to eq(:splat)
  end
end
