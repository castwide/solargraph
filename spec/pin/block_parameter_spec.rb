describe Solargraph::Pin::BlockParameter do
  it "detects block parameter return types from @param tags" do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      def foo bar
      end
    ), 'file.rb')
    expect(source.local_variable_pins.length).to eq(1)
    expect(source.local_variable_pins.first.return_type).to eq('String')
  end
end
