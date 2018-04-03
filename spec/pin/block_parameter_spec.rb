describe Solargraph::Pin::BlockParameter do
  it "detects block parameter return types from @yieldparam tags" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      # @yieldparam [Array]
      def yielder
      end

      yielder do |things|
      end
    ), 'file.rb')
    api_map.virtualize source
    expect(source.local_variable_pins.length).to eq(1)
    source.local_variable_pins.first.resolve api_map
    expect(source.local_variable_pins.first.name).to eq('things')
    expect(source.local_variable_pins.first.return_type).to eq('Array')
  end

  it "detects block parameter return types from core methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      String.new.split.each do |str|
      end
    ), 'file.rb')
    api_map.virtualize source
    expect(source.local_variable_pins.length).to eq(1)
    source.local_variable_pins.first.resolve api_map
    expect(source.local_variable_pins.first.name).to eq('str')
    expect(source.local_variable_pins.first.return_type).to eq('String')
  end
end
