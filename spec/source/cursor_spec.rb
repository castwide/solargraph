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

  it "detects arguments inside parentheses" do
    source = Solargraph::Source.load_string('a(1); b')
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

  it 'detects arguments at opening parentheses' do
    source = Solargraph::Source.load_string('String.new', 'test.rb')
    change = Solargraph::Source::Change.new(Solargraph::Range.from_to(0, 10, 0, 10) ,'(')
    updater = Solargraph::Source::Updater.new('test.rb', 1, [change])
    source = source.synchronize(updater)
    cursor = source.cursor_at([0, 11])
    expect(cursor).to be_argument
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

  it 'avoids errant string? detection from nearby dstr nodes' do
    source = Solargraph::Source.load_string(%(
      source = some_call(%(
        class Foo; end
      ))
      String.new(S)
    ))
    cursor = source.cursor_at(Solargraph::Position.new(4, 18))
    expect(cursor.string?).to be(false)
  end

  it 'does not detect string? at end of interpolation' do
    source = Solargraph::Source.load_string('
      "#{a}"
    ')
    cursor = source.cursor_at(Solargraph::Position.new(1, 10))
    expect(cursor.string?).to be(false)
  end

  it 'detects strings outside of interpolation in unsynchronized sources' do
    source = Solargraph::Source.load_string('
      "#{[]}"
    ', 'test.rb')
    updater = Solargraph::Source::Updater.new('test.rb', 1, [
      Solargraph::Source::Change.new(Solargraph::Range.from_to(1, 12, 1, 12), '.')
    ])
    updated = source.synchronize(updater)
    cursor = updated.cursor_at(Solargraph::Position.new(1, 13))
    expect(cursor).to be_string
  end

  it 'returns recipient cursors' do
    source = Solargraph::Source.load_string(%(
      recipient(argument)
    ))
    r = source.cursor_at(Solargraph::Position.new(1, 6))
    a = source.cursor_at(Solargraph::Position.new(1, 16))
    expect(a.recipient.node).to eq(r.node)
  end
end
