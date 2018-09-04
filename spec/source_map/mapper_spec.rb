describe Solargraph::SourceMap::Mapper do
  it "creates `new` pins for `initialize` pins" do
    source = Solargraph::Source.new(%(
      class Foo
        def initialize; end
      end

      class Foo::Bar
        def initialize; end
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo.new'}.first
    expect(foo_pin.return_type.tag).to eq('Foo')
    bar_pin = map.pins.select{|pin| pin.path == 'Foo::Bar.new'}.first
    expect(bar_pin.return_type.tag).to eq('Foo::Bar')
  end

  it "ignores include calls that are not attached to the current namespace" do
    source = Solargraph::Source.new(%(
      class Foo
        include Direct
        xyz.include Indirect
        xyz(include Indirect)
      end
    ))
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo'}.first
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
    map = Solargraph::SourceMap.map(source)
    foo_pin = map.pins.select{|pin| pin.path == 'Foo'}.first
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
    map = Solargraph::SourceMap.map(source)
    bar1 = map.pins.select{|pin| pin.name == 'bar1'}.first
    expect(bar1.scope).to eq(:instance)
    bar2 = map.pins.select{|pin| pin.name == 'bar2'}.first
    expect(bar2.scope).to eq(:class)
  end

  it "sets attribute visibility" do
    map = Solargraph::SourceMap.load_string(%(
      module Foo
        attr_reader :default_public_method
        private
        attr_reader :private_method
        protected
        attr_reader :protected_method
        public
        attr_reader :explicit_public_method
      end
    ))
    expect(map.first_pin('Foo#default_public_method').visibility).to eq(:public)
    expect(map.first_pin('Foo#private_method').visibility).to eq(:private)
    expect(map.first_pin('Foo#protected_method').visibility).to eq(:protected)
    expect(map.first_pin('Foo#explicit_public_method').visibility).to eq(:public)
  end
end
