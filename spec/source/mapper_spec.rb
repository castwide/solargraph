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

  it "ignores include calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        include Direct
        xyz.include Indirect
        xyz(include Indirect)
      end
    ))
    foo_pin = source.pins.select{|pin| pin.path == 'Foo'}.first
    expect(foo_pin.include_references.map(&:name)).to include('Direct')
    expect(foo_pin.include_references.map(&:name)).not_to include('Indirect')
  end

  it "ignores extend calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        extend Direct
        xyz.extend Indirect
        xyz(extend Indirect)
      end
    ))
    foo_pin = source.pins.select{|pin| pin.path == 'Foo'}.first
    expect(foo_pin.extend_references.map(&:name)).to include('Direct')
    expect(foo_pin.extend_references.map(&:name)).not_to include('Indirect')
  end

  it "sets scopes for attributes" do
    source = Solargraph::Source.new(%(
      module Foo
        attr_reader :bar1
        class << self
          attr_reader :bar2
        end
      end
    ))
    bar1 = source.pins.select{|pin| pin.name == 'bar1'}.first
    expect(bar1.scope).to eq(:instance)
    bar2 = source.pins.select{|pin| pin.name == 'bar2'}.first
    expect(bar2.scope).to eq(:class)
  end
end
