# frozen_string_literal: true

describe Solargraph::Pin::ExpressionNarrowing do
  # @param code [String]
  # @return [Array<Array>, nil]
  def steps_of code
    node = Solargraph::Parser.parse(code)
    node = node.children.last if node.type == :begin
    described_class.steps_from_node(node)
  end

  let(:api_map) do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar h
          h[:k]
          [1].each { |h| h[:k] }
        end

        def baz
        end
      end
    ), 'test.rb')
    Solargraph::ApiMap.new.tap { |map| map.map source }
  end
  let(:bar) { pins.find { |pin| pin.path == 'Foo#bar' } }
  let(:block) { pins.find { |pin| pin.is_a?(Solargraph::Pin::Block) } }

  # @return [Array<Solargraph::Pin::Base>]
  def pins
    api_map.source_map('test.rb').pins + api_map.source_map('test.rb').locals
  end

  # @return [Solargraph::Pin::ExpressionNarrowing]
  def narrowing **attrs
    described_class.new(steps: [%i[lvar h], [:call, :[], [%i[literal sym k]]]],
                        presence: Solargraph::Range.from_to(3, 0, 4, 50), closure: bar,
                        location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(2, 0, 2, 0)),
                        **attrs)
  end

  # @param line [Integer]
  # @param file [String]
  # @return [Solargraph::Location]
  def loc line, file = 'test.rb'
    Solargraph::Location.new(file, Solargraph::Range.from_to(line, 10, line, 10))
  end

  describe '.steps_from_node' do
    it 'reads variable roots' do
      expect([steps_of('h = 1; h'), steps_of('@h'), steps_of('@@h')])
        .to eq([[%i[lvar h]], [%i[ivar @h]], [%i[cvar @@h]]])
    end

    it 'reads argument-less calls on self or a narrowable receiver' do
      expect(steps_of('self.name')).to eq([%i[self_call name]])
      expect(steps_of('@a.b.c')).to eq([%i[ivar @a], %i[call b], %i[call c]])
    end

    it 'reads indexes with a literal or variable key' do
      expect(steps_of('@h[:k]')).to eq([%i[ivar @h], [:call, :[], [%i[literal sym k]]]])
      expect(steps_of('@h[@k]')).to eq([%i[ivar @h], [:call, :[], [%i[ivar @k]]]])
    end

    it 'rejects calls with arguments, computed keys and non-variable roots' do
      expect([steps_of('@a.b(1)'), steps_of('@h[@a.b]'), steps_of('@h[1, 2]'),
              steps_of('foo(1)'), steps_of('self[:k]'), steps_of('Foo.bar')]).to all(be_nil)
    end
  end

  it 'is a Narrowing whose narrowing_subject is its steps' do
    expect(narrowing).to be_a(Solargraph::Pin::Narrowing)
    expect(narrowing.narrowing_subject).to eq(narrowing.steps)
  end

  describe '#visible_at?' do
    it 'is visible in its presence in its closure and nested closures' do
      expect(narrowing.visible_at?(bar, loc(3))).to be true
      expect(narrowing.visible_at?(block, loc(4))).to be true
    end

    it 'is not visible outside its presence, file or closure' do
      expect(narrowing.visible_at?(bar, loc(7))).to be false
      expect(narrowing.visible_at?(bar, loc(3, 'other.rb'))).to be false
      expect(narrowing.visible_at?(pins.find { |pin| pin.path == 'Foo#baz' }, loc(3))).to be false
    end
  end

  describe '#proves?' do
    # @param closure [Solargraph::Pin::Closure]
    # @return [Solargraph::Pin::LocalVariable]
    def h_in closure
      pins.find { |pin| pin.is_a?(Solargraph::Pin::LocalVariable) && pin.name == 'h' && pin.closure == closure }
    end

    let(:outer_h) { h_in(bar) }

    it 'applies to an expression reading the same variables' do
      expect(narrowing.proves?(api_map, [outer_h])).to be true
    end

    it 'does not apply to a same-named variable of a nested closure' do
      expect(narrowing.proves?(api_map, [h_in(block)])).to be false
    end

    it 'applies only when its check holds' do
      expect(narrowing(check: ->(_api_map) { true }).proves?(api_map, [outer_h])).to be true
      expect(narrowing(check: ->(_api_map) { false }).proves?(api_map, [outer_h])).to be false
    end
  end

  it 'treats module_function copies of a method as one closure' do
    source = Solargraph::Source.load_string(%(
      module Mod
        module_function

        def bar h
          h
        end
      end
    ), 'mod.rb')
    source_map = Solargraph::SourceMap.map(source)
    copies = source_map.pins.select { |pin| pin.is_a?(Solargraph::Pin::Method) && pin.name == 'bar' }
    h = source_map.locals.find { |pin| pin.name == 'h' }
    narrowing = described_class.new(steps: [%i[lvar h], %i[call size]], presence: Solargraph::Range.from_to(4, 0, 6, 0),
                                    closure: copies.first,
                                    location: Solargraph::Location.new('mod.rb', Solargraph::Range.from_to(4, 0, 4, 0)))
    expect(copies.map(&:scope)).to contain_exactly(:class, :instance)
    expect(copies.map { |copy| narrowing.visible_at?(copy, loc(5, 'mod.rb')) }).to eq([true, true])
    expect(narrowing.proves?(api_map, [h])).to be true
  end

  describe '#narrow' do
    it 'excludes and intersects types' do
      type = Solargraph::ComplexType.parse('Integer', 'String', 'nil')
      result = narrowing(exclude_return_type: Solargraph::ComplexType::NIL,
                         intersection_return_type: Solargraph::ComplexType.parse('String'))
               .narrow(type, api_map)
      expect(result.to_s).to eq('String')
    end
  end
end
