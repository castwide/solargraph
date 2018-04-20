describe Solargraph::Pin::Constant do
  it "resolves constant paths" do
    source = Solargraph::Source.new(%(
      class Foo
        BAR = 'bar'
      end
    ))
    pin = source.pins.select{|pin| pin.name == 'BAR'}.first
    expect(pin.path).to eq('Foo::BAR')
  end
end
