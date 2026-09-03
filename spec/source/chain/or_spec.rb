# frozen_string_literal: true

describe Solargraph::Source::Chain::Or do
  it 'handles simple nil-removal' do
    source = Solargraph::Source.load_string(%(
      # @param a [Integer, nil]
      def foo a
        b = a || 10
        b
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    clip = api_map.clip_at('test.rb', [4, 8])
    expect(clip.infer.simplify_literals.rooted_tags).to eq('::Integer')
  end

  it 'removes nil from more complex cases' do
    source = Solargraph::Source.load_string(%(
      def foo
        out = ENV['BAR'] ||
          File.join(Dir.home, '.config', 'solargraph', 'config.yml')
        out
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    clip = api_map.clip_at('test.rb', [3, 8])
    expect(clip.infer.simplify_literals.rooted_tags).to eq('::String')
  end

  it 'infers just the lhs type when the rhs always raises' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @param argv [Array<String>]
        # @return [String]
        def first_arg(argv)
          argv[0] || raise('missing first argument')
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    checker = Solargraph::TypeChecker.new('test.rb', api_map: api_map)
    expect(checker.problems).to be_empty
  end

  it 'strips nil from the lhs type when the rhs always raises' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @param argv [Array<String>]
        # @return [String]
        def first_arg(argv)
          x = argv[0] || raise('missing first argument')
          x
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [6, 10])
    expect(clip.infer.simplify_literals.rooted_tags).to eq('::String')
  end

  it 'infers just the lhs type when the rhs always fails via ||=' do
    source = Solargraph::Source.load_string(%(
      class Example
        # @param name [String, nil]
        # @return [String]
        def resolved_name(name)
          name ||= raise('name required')
          name
        end
      end
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)
    checker = Solargraph::TypeChecker.new('test.rb', api_map: api_map)
    expect(checker.problems).to be_empty
  end

  it 'falls back to undefined when the rhs never returns but there is no lhs type to infer' do
    or_link = described_class.new([], rhs_never_returns: true)
    api_map = Solargraph::ApiMap.new
    pin = or_link.resolve(api_map, nil, []).first
    expect(pin.return_type.tag).to eq('undefined')
  end
end
