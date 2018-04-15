describe Solargraph::Pin::MethodParameter do
  it "detects method parameter return types from @param tags" do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      def foo bar
      end
    ), 'file.rb')
    expect(source.locals.length).to eq(1)
    expect(source.locals.first.name).to eq('bar')
    expect(source.locals.first.return_type).to eq('String')
  end
end
