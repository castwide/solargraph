describe Solargraph::Source::Cursor do
  it "detects cursors in strings" do
    source = Solargraph::Source.load_string('str = "string"')
    cursor = described_class.new(source, Solargraph::Position.new(0, 6))
    expect(cursor).not_to be_string
    cursor = described_class.new(source, Solargraph::Position.new(0, 7))
    expect(cursor).to be_string
  end

  it "detects cursors in comments" do
    source = Solargraph::Source.load_string(%(
      # @type [String]
      var = make_a_string
    ))
    cursor = described_class.new(source, Solargraph::Position.new(1, 6))
    expect(cursor).not_to be_comment
    cursor = described_class.new(source, Solargraph::Position.new(1, 7))
    expect(cursor).to be_comment
    cursor = described_class.new(source, Solargraph::Position.new(2, 0))
    expect(cursor).not_to be_comment
  end

  it "detects arguments" do
    source = double(:Source, :code => 'a(1), b')
    cur = described_class.new(source, Solargraph::Position.new(0,2))
    expect(cur).to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,3))
    expect(cur).to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,4))
    expect(cur).not_to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,5))
    expect(cur).not_to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,7))
    expect(cur).not_to be_argument
  end

  it "detects class variables" do
    source = double(:Source, :code => '@@foo')
    cur = described_class.new(source, Solargraph::Position.new(0, 2))
    expect(cur.word).to eq('@@foo')
  end

  it "detects instance variables" do
    source = double(:Source, :code => '@foo')
    cur = described_class.new(source, Solargraph::Position.new(0, 1))
    expect(cur.word).to eq('@foo')
  end

  it "detects global variables" do
    source = double(:Source, :code => '@foo')
    cur = described_class.new(source, Solargraph::Position.new(0, 1))
    expect(cur.word).to eq('@foo')
  end

  it "generates word ranges" do
    source = Solargraph::Source.load_string(%(
      foo = bar
    ))
    cur = described_class.new(source, Solargraph::Position.new(1, 15))
    expect(source.at(cur.range)).to eq('bar')
  end

  it "detects recipients" do
    source = double(:Source, :code => 'a(1), b')
    cur = described_class.new(source, Solargraph::Position.new(0, 2))
    expect(cur.recipient.word).to eq('a')
  end

  it "generates chains" do
    source = Solargraph::Source.load_string('foo.bar(1,2).baz{}')
    cur = described_class.new(source, Solargraph::Position.new(0, 18))
    expect(cur.chain).to be_a(Solargraph::Source::Chain)
    expect(cur.chain.links.map(&:word)).to eq(['foo', 'bar', 'baz'])
  end

  it "detects constant words" do
    source = double(:Source, :code => 'Foo::Bar')
    cur = described_class.new(source, Solargraph::Position.new(0, 5))
    expect(cur.word).to eq('Bar')
  end

  it "detects cursors in dynamic strings" do
    source = Solargraph::Source.load_string('"#{100}"')
    cursor = source.cursor_at(Solargraph::Position.new(0, 7))
    expect(cursor).to be_string
  end

  it "detects cursors in embedded strings" do
    source = Solargraph::Source.load_string('"#{100}..."')
    cursor = source.cursor_at(Solargraph::Position.new(0, 10))
    expect(cursor).to be_string
  end
end
