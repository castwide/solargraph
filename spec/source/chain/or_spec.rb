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
end
