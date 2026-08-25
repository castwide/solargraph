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

  it 'infers a splat target in a multiple assignment as an array' do
    source = Solargraph::Source.load_string(%(
      class Repro
        # @param mutator [Array<Symbol, BasicObject>]
        # @return [void]
        def call(mutator)
          command, *args = mutator
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    locals = api_map.source_map('test.rb').locals
    command_pin = locals.find { |l| l.name == 'command' }
    args_pin = locals.find { |l| l.name == 'args' }
    expect(command_pin.probe(api_map).tag).to eq('Symbol')
    expect(args_pin.probe(api_map).tag).to eq('Array<Symbol, BasicObject>')
  end

  it 'infers a splat target from a user-defined class that includes Enumerable' do
    source = Solargraph::Source.load_string(%(
      # @generic Elem
      class MyBag
        include Enumerable

        # @yieldparam [generic<Elem>]
        # @return [void]
        def each; end
      end

      class Repro
        # @param bag [MyBag<String>]
        # @return [void]
        def call(bag)
          first, *rest = bag
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    locals = api_map.source_map('test.rb').locals
    first_pin = locals.find { |l| l.name == 'first' }
    rest_pin = locals.find { |l| l.name == 'rest' }
    expect(first_pin.probe(api_map).tag).to eq('String')
    expect(rest_pin.probe(api_map).tag).to eq('Array<String>')
  end

  it 'gives every non-splat target the full element union of a non-tuple Array' do
    # Array<Integer, String> (no tuple parens) declares a union of
    # possible element types, not a positional tuple, so every
    # position - a and b alike - can hold either member. Note: #tag
    # delegates to the first union member only, so a multi-member
    # union must be asserted with #to_s instead, or a regression that
    # collapses the union to its first member would still pass here.
    source = Solargraph::Source.load_string(%(
      class Repro
        # @param pair [Array<Integer, String>]
        # @return [void]
        def call(pair)
          a, b = pair
        end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    locals = api_map.source_map('test.rb').locals
    a_pin = locals.find { |l| l.name == 'a' }
    b_pin = locals.find { |l| l.name == 'b' }
    expect(a_pin.probe(api_map).to_s).to eq('Integer, String')
    expect(b_pin.probe(api_map).to_s).to eq('Integer, String')
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
