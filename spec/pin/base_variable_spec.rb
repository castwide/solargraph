# frozen_string_literal: true

describe Solargraph::Pin::BaseVariable do
  it 'checks assignments for equality' do
    smap = Solargraph::SourceMap.load_string('foo = "foo"')
    pin1 = smap.locals.first
    smap = Solargraph::SourceMap.load_string('foo = "foo"')
    pin2 = smap.locals.first
    expect(pin1).to eq(pin2)
    smap = Solargraph::SourceMap.load_string('foo = "bar"')
    pin2 = smap.locals.first
    expect(pin1).not_to eq(pin2)
  end

  it 'includes presence and narrowed/exclude return type in #eql? and #hash' do
    # Equality#eql?/#hash (used by Array#uniq, Set, and Hash keys) key off
    # of #equality_fields. Flow-sensitive typing downcasts a pin into
    # copies that share name/location/closure/source but differ in
    # presence/narrowed_return_type/exclude_return_type - those copies
    # must stay distinct as eql?/hash keys.
    location = Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 1, 0))
    presence1 = Solargraph::Range.from_to(0, 0, 0, 5)
    presence2 = Solargraph::Range.from_to(1, 0, 1, 5)
    pin1 = Solargraph::Pin::LocalVariable.new(name: 'foo', location: location, presence: presence1)
    pin2 = Solargraph::Pin::LocalVariable.new(name: 'foo', location: location, presence: presence2)
    expect(pin1.eql?(pin2)).to be(false)
    expect(pin1.hash).not_to eq(pin2.hash)
  end

  it 'infers types from variable assignments with unparenthesized parameters' do
    source = Solargraph::Source.load_string(%(
      class Container
        def initialize; end
      end
      cnt = Container.new param1, param2
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.source_map('test.rb').locals.first
    type = pin.probe(api_map)
    expect(type.tag).to eq('Container')
  end

  it 'infers from nil nodes without locations' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
          @bar =
            if baz
              1
            end
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_instance_variable_pins('Foo').first
    type = pin.probe(api_map)
    expect(type.tags).to eq('Integer, nil')
    expect(type.simple_tags).to eq('Integer, nil')
    expect(type.to_rbs).to eq('(::Integer | nil)')
    expect(type.simplify_literals.to_rbs).to eq('(::Integer | nil)')
  end

  it "understands proc kwarg parameters aren't affected by @type" do
    code = %(
      # @return [Proc]
      def foo
        # @type [Proc]
        # @param layout [Boolean]
        @render_method = proc { |layout = false|
          123 if layout
        }
      end
    )
    checker = Solargraph::TypeChecker.load_string(code, 'test.rb', :alpha)
    expect(checker.problems.map(&:message)).to eq([])
  end
end
