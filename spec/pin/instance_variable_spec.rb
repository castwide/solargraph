describe Solargraph::Pin::InstanceVariable do
  it "detects instance variables by scope" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
          @bar = 'string'
          @bar
        end
        @bar = [1,2,3]
        @bar
      end
    ), 'file.rb')
    api_map.virtualize source
    ifrag = source.fragment_at(4, 14)
    ipin = api_map.complete(ifrag).pins.select{|pin| pin.name == '@bar'}.first
    expect(ipin.return_type).to eq('String')
    cfrag = source.fragment_at(7, 12)
    cpin = api_map.complete(cfrag).pins.select{|pin| pin.name == '@bar'}.first
    expect(cpin.return_type).to eq('Array')
  end
end
