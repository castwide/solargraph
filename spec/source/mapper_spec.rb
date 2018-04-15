describe Solargraph::Source::Mapper do
  it "creates `new` pins for `initialize` pins" do
    source = Solargraph::Source.new(%(
      class Foo
        def initialize; end
      end

      class Foo::Bar
        def initialize; end
      end
    ))
    foo_pin = source.pins.select{|pin| pin.path == 'Foo.new'}.first
    expect(foo_pin.return_type).to eq('Foo')
    bar_pin = source.pins.select{|pin| pin.path == 'Foo::Bar.new'}.first
    expect(bar_pin.return_type).to eq('Foo::Bar')
  end
end
