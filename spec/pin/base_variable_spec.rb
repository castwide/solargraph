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
    expect(type.tags).to eq('1, nil')
    expect(type.simple_tags).to eq('Integer, nil')
    expect(type.to_rbs).to eq('(1 | nil)')
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

  # `return_types_from_node` hides the pin(s) belonging to this exact
  # assignment while resolving its own right-hand side. The pins it hides
  # must be limited to the same variable: a pin for a *different* variable
  # that happens to share the assignment node is not a self-reference, and
  # hiding it drops the type that pin carries. Flow-sensitive typing
  # produces exactly that shape when it synthesizes a narrowed pin for a
  # bare, implicit-self accessor call, which reuses the call node that the
  # surrounding assignment also stores.
  describe 'resolving an assignment against the other local pins' do
    it 'keeps a differently-named pin that shares the assignment node' do
      code = %(
        class Repro
          # @return [String]
          def steps; end

          def run
            local = steps
            local
          end
        end
      )
      source_map = Solargraph::SourceMap.load_string(code, 'test.rb')
      local_pin = source_map.locals.find { |pin| pin.name == 'local' }
      source_map.locals.push(
        Solargraph::Pin::LocalVariable.new(
          location: local_pin.location,
          closure: local_pin.closure,
          name: 'steps',
          assignment: local_pin.assignment,
          return_type: Solargraph::ComplexType.parse('Integer'),
          presence: local_pin.closure.location.range,
          source: :flow_sensitive_typing
        )
      )
      api_map = Solargraph::ApiMap.new.catalog(Solargraph::Bench.new(source_maps: [source_map]))
      pin = api_map.source_map('test.rb').locals.find { |local| local.name == 'local' }

      # Integer from the pin pushed above, not String from Repro#steps.
      expect(pin.probe(api_map).rooted_tags).to eq('::Integer')
    end

    it 'still hides the same variable on a genuine self-reference' do
      source = Solargraph::Source.load_string(%(
        index = 0
        index += 1
        index
      ), 'test.rb')
      api_map = Solargraph::ApiMap.new.map(source)

      # `index += 1` desugars to `index = index + 1`; resolving that
      # right-hand side against index's own not-yet-computed pin would
      # answer with the stale literal 0.
      expect(api_map.clip_at('test.rb', [3, 13]).infer.to_s).to eq('Integer')
    end
  end
end
