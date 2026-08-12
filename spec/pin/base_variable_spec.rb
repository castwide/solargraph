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

  it 'treats combine_with results with the same location but different presence as unequal' do
    # combine_with results choose the earliest assignment's #location,
    # so two combine_with results over a different number of
    # assignments to the same variable can share #location while
    # covering different #presence ranges. Pin::Base#== only compared
    # location, not presence, so these looked equal to any caller
    # keying off of #== (e.g. Array#include?, used by Chain's inference
    # recursion guard) even though they represent different sets of
    # possible values for the variable.
    source = Solargraph::Source.load_string(%(
      def go(str)
        str = str.gsub('a', 'b')
        str = str.gsub('c', 'd')
        str
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    smap = api_map.source_map('test.rb')
    param = smap.locals.find { |p| p.name == 'str' && p.is_a?(Solargraph::Pin::Parameter) }
    first_assignment = smap.locals.find { |p| p.name == 'str' && p.location.range.start.line == 2 }
    second_assignment = smap.locals.find { |p| p.name == 'str' && p.location.range.start.line == 3 }

    combined_through_first = param.combine_with(first_assignment)
    combined_through_second = combined_through_first.combine_with(second_assignment)

    expect(combined_through_first.location).to eq(combined_through_second.location)
    expect(combined_through_first.presence).not_to eq(combined_through_second.presence)
    expect(combined_through_first).not_to eq(combined_through_second)
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
