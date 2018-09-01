describe Solargraph::SourceMap::Fragment do
  before :all do
    @call_source_map = Solargraph::SourceMap.map(Solargraph::Source.new("@foo = foo.bar(one, :two){|baz| puts 'hello'"))
    @name_source_map = Solargraph::SourceMap.map(Solargraph::Source.new(%(
      class Foo
        def bar
          @bar
        end
        def self.baz
          lvar = 'one'
          @baz
        end
      end
    )))
  end

  it "accepts arrays or positions" do
    f1 = described_class.new(@call_source_map, [0, 2])
    f2 = described_class.new(@call_source_map, Solargraph::Position.new(0, 2))
    expect(f1.word).to eq(f2.word)
    expect(f1.range).to eq(f2.range)
    expect(f1.context).to eq(f2.context)
  end

  it "get the position's word" do
    fragment = described_class.new(@call_source_map, [0, 2])
    expect(fragment.word).to eq('@foo')
  end

  it "gets the start of the word" do
    fragment = described_class.new(@call_source_map, [0, 2])
    expect(fragment.start_of_word).to eq('@f')
  end

  it "gets the end of the word" do
    fragment = described_class.new(@call_source_map, [0, 2])
    expect(fragment.end_of_word).to eq('oo')
  end

  it "gets the context of the root" do
    fragment = described_class.new(@name_source_map, [1, 0])
    expect(fragment.context.namespace).to eq('')
    expect(fragment.context.scope). to eq(:class)
  end

  it "gets the context inside a class" do
    fragment = described_class.new(@name_source_map, [2, 0])
    expect(fragment.context.namespace).to eq('Foo')
    expect(fragment.context.scope).to eq(:class)
  end

  it "gets the context inside an instance method" do
    fragment = described_class.new(@name_source_map, [3, 0])
    expect(fragment.context.namespace).to eq('Foo')
    expect(fragment.context.scope).to eq(:instance)
  end

  it "gets the context inside a class method" do
    fragment = described_class.new(@name_source_map, [6, 0])
    expect(fragment.context.namespace).to eq('Foo')
    expect(fragment.context.scope).to eq(:class)
  end

  it "recognizes symbols" do
    fragment = described_class.new(@call_source_map, [0, 21])
    expect(fragment.word).to eq(':two')
  end

  it "finds word ranges" do
    fragment = described_class.new(@call_source_map, [0, 8])
    expect(@call_source_map.source.at(fragment.range)).to eq('foo')
  end

  it "generates chains" do
    fragment = described_class.new(@call_source_map, [0, 12])
    expect(fragment.chain).to be_a(Solargraph::SourceMap::Chain)
  end

  it "finds locals" do
    fragment = described_class.new(@name_source_map, [7, 0])
    expect(fragment.locals.length).to eq(1)
    expect(fragment.locals.first.name).to eq('lvar')
  end

  it "finds recipients" do
    fragment = described_class.new(@call_source_map, [0, 15])
    expect(fragment.argument?).to be(true)
    expect(fragment.recipient).to be_a(Solargraph::SourceMap::Fragment)
  end

  it "detects a lack of recipients at a method call" do
    fragment = described_class.new(@call_source_map, [0, 8])
    expect(fragment.argument?).to be(false)
    expect(fragment.recipient).to be_nil
  end

  it "detects lack of recipients at the root" do
    fragment = described_class.new(@call_source_map, [0, 25])
    expect(fragment.argument?).to be(false)
    expect(fragment.recipient).to be_nil
  end
end
