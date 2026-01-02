describe Solargraph::Source::Chain::QCall do
  it 'understands &. in chains' do
    source = Solargraph::Source.load_string(%(
      # @param a [String, nil]
      # @return [String, nil]
      def foo a
        b = a&.upcase
        b
      end

      b = foo 123
      b
    ), 'test.rb')

    api_map = Solargraph::ApiMap.new.map(source)

    clip = api_map.clip_at('test.rb', [5, 8])
    expect(clip.infer.to_s).to eq('String, nil')

    clip = api_map.clip_at('test.rb', [9, 6])
    expect(clip.infer.to_s).to eq('String, nil')
  end
end
