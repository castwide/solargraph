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

  describe '#probe_blame' do
    # @param assigned [String] the expression assigned to @baz
    # @return [Array(Solargraph::ApiMap, Solargraph::Pin::BaseVariable)]
    def ivar_pin_for assigned
      api_map = Solargraph::ApiMap.new
      api_map.map Solargraph::Source.load_string(%(
        class Foo
          def bar
            @baz = #{assigned}
          end
        end
      ), 'test.rb')
      [api_map, api_map.get_instance_variable_pins('Foo').first]
    end

    it 'returns nil when every assignment infers cleanly' do
      api_map, pin = ivar_pin_for('String.new.upcase')
      expect(pin.probe_blame(api_map)).to be_nil
    end

    it 'reports the failing link of the assigned expression' do
      api_map, pin = ivar_pin_for('String.new.no_such_method')
      expect(pin.probe_blame(api_map).link.word).to eq('no_such_method')
    end
  end
end
