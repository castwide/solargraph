describe Solargraph::Pin::MethodParameter do
  it "detects method parameter return types from @param tags" do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      def foo bar
      end
    ), 'file.rb')
    map = Solargraph::SourceMap.map(source)
    expect(map.locals.length).to eq(1)
    expect(map.locals.first.name).to eq('bar')
    expect(map.locals.first.return_type).to eq('String')
  end
end
