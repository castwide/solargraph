describe Solargraph::Source do
  it "parses code" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    expect(source.code).to eq(code)
    expect(Solargraph::Parser.is_ast_node?(source.node)).to be_truthy
    expect(source).to be_parsed
  end

  it "fixes invalid code" do
    code = 'class Foo; def bar; x.'
    source = described_class.new(code)
    expect(source.code).to eq(code)
    # @todo Unparsed code is resulting in nil nodes, maybe temporarily.
    #   See Solargraph::Source#initialize
    # expect(source.node).to be_a(Parser::AST::Node)
    expect(source).not_to be_parsed
  end

  it "finds ranges" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    source = described_class.new(code)
    range = Solargraph::Range.new(Solargraph::Position.new(2, 8), Solargraph::Position.new(2, 15))
    expect(source.at(range)).to eq('def bar')
  end

  it "finds nodes" do
    # @todo This test is specific to Parser and breaks with RubyVM.
    next if Solargraph::Parser.rubyvm?
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    node = source.node_at(0, 0)
    expect(node.type).to eq(:class)
    node = source.node_at(0, 10)
    expect(node.type).to eq(:def)
  end

  it "synchronizes from incremental updates" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(
      nil, 0, [Solargraph::Source::Change.new(
        Solargraph::Range.new(
          Solargraph::Position.new(0, 9),
          Solargraph::Position.new(0, 9)
        ),
        'd'
      )]
    )
    changed = source.synchronize(updater)
    expect(changed.code).to start_with('class Food;')
    # @todo This test is specific to Parser and breaks with RubyVM.
    next if Solargraph::Parser.rubyvm?
    expect(changed.node.children[0].children[1]).to eq(:Food)
  end

  it "synchronizes from full updates" do
    code1 = 'class Foo;end'
    code2 = 'class Bar;end'
    source = described_class.new(code1)
    updater = Solargraph::Source::Updater.new(nil, 0, [
      Solargraph::Source::Change.new(nil, code2)
    ])
    changed = source.synchronize(updater)
    expect(changed.code).to eq(code2)
    # @todo This test is specific to Parser and breaks with RubyVM.
    next if Solargraph::Parser.rubyvm?
    expect(changed.node.children[0].children[1]).to eq(:Bar)
  end

  it "repairs broken incremental updates" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(
      nil, 0, [Solargraph::Source::Change.new(
        Solargraph::Range.new(
          Solargraph::Position.new(3, 0),
          Solargraph::Position.new(3, 1)
        ),
        '@'
      )]
    )
    changed = source.synchronize(updater)
    expect(changed).to be_parsed
    expect(changed).to be_repaired
  end

  it "flags irreparable updates" do
    code = 'class Foo;def bar;end;end'
    source = described_class.new(code)
    updater = Solargraph::Source::Updater.new(nil, 0, [
      Solargraph::Source::Change.new(nil, 'end;end')
    ])
    changed = source.synchronize(updater)
    expect(changed).to be_parsed
    expect(changed).to be_repaired
  end

  it "finds references" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
        def bar=
        end
      end
      𐐀 = Foo.new # unicode name to test offset
      𐐀.bar
      𐐀.bar = 1
    ))
    foos = source.references('Foo')
    foobacks = foos.map{|f| source.at(f.range)}
    expect(foobacks).to eq(['Foo', 'Foo'])
    bars = source.references('bar')
    barbacks = bars.map{|b| source.at(b.range)}
    expect(barbacks).to eq(['bar', 'bar'])
    assign_bars = source.references('bar=')
    assign_barbacks = assign_bars.map{|b| source.at(b.range)}
    expect(assign_barbacks).to eq(['bar=', 'bar ='])
  end

  it "allows escape sequences incompatible with UTF-8" do
    source = Solargraph::Source.new('
      x = " Un bUen café \x92"
      puts x
    ')
    expect(source.parsed?).to be(true)
  end

  it "fixes invalid byte sequences in UTF-8 encoding" do
    expect {
      Solargraph::Source.load('spec/fixtures/invalid_byte.rb')
    }.not_to raise_error
  end

  it "loads files with Unicode characters" do
    expect {
      Solargraph::Source.load('spec/fixtures/unicode.rb')
    }.not_to raise_error
  end

  it "updates itself when code does not change" do
    original = Solargraph::Source.load_string('x = y', 'test.rb')
    updater = Solargraph::Source::Updater.new('test.rb', 1, [])
    updated = original.synchronize(updater)
    expect(original).to be(updated)
    expect(updated.version).to eq(1)
  end

  it "handles unparseable code" do
    source = Solargraph::Source.load_string(%(
      100.times do |num|
    ))
    # @todo Unparseable code results in a nil node for now, but that could
    #   change. See Solargraph::Source#initialize
    expect(source.node).to be_nil
    expect(source.parsed?).to be(false)
  end

  it "finds foldable ranges" do
    # Of the 7 possible ranges, 2 are too short to be foldable
    source = Solargraph::Source.load_string(%(
=begin
Range 1
=end
def range_2
  x = y
  puts z
end
# Range 3.1
# Range 3.2
# Range 3.3
a = b
# Range 4.1 (too short)
# Range 4.2
c = b
# Range 5.1 (too short)
d = c # inline
# Range 6.1
# Range 6.2
# Range 6.3
e = d # inline
# Range 7.1
# Range 7.2
# Range 7.3
    ))
    expect(source.folding_ranges.length).to eq(5)
  end

  it 'folds multiline strings' do
    source = Solargraph::Source.load_string(%(
      a = 1
      b = 2
      c = 3
      d = %(
        one
        two
        three
      )
    ))
    expect(source.folding_ranges).to be_one
    expect(source.folding_ranges.first.start.line).to eq(4)
  end

  it 'folds multiline arrays' do
    source = Solargraph::Source.load_string(%(
      a = 1
      b = 2
      c = 3
      d = [
        one,
        two,
        three
      ]
    ))
    expect(source.folding_ranges).to be_one
    expect(source.folding_ranges.first.start.line).to eq(4)
  end

  it 'folds multiline hashes' do
    source = Solargraph::Source.load_string(%(
      a = 1
      b = 2
      c = 3
      d = {
        one: 1,
        two: 2,
        three: 3
      }
    ))
    expect(source.folding_ranges).to be_one
    expect(source.folding_ranges.first.start.line).to eq(4)
  end

  it "returns unsynchronized sources for started synchronizations" do
    source1 = Solargraph::Source.load_string('x = 1', 'test.rb')
    source2 = source1.start_synchronize Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(0, 5, 0, 5),
          '2'
        )
      ]
    )
    expect(source2.code).to eq('x = 12')
    expect(source2).not_to be_synchronized
  end

  it "finishes synchronizations for unbalanced lines" do
    source1 = Solargraph::Source.load_string('x = 1', 'test.rb')
    source2 = source1.start_synchronize Solargraph::Source::Updater.new(
      'test.rb',
      2,
      [
        Solargraph::Source::Change.new(
          Solargraph::Range.from_to(0, 5, 0, 5),
          "\n2"
        )
      ]
    )
    expect(source2.code).to eq("x = 1\n2")
    expect(source2).to be_synchronized
  end

  it "handles comment arrays that overlap lines" do
    # Fixes negative argument error (castwide/solargraph#141)
    source = Solargraph::Source.load_string(%(
=begin
=end
y = 1 #foo
    ))
    node = source.node_at(3, 0)
    expect {
      source.comments_for(node)
    }.not_to raise_error
  end

  it "formats comments with multiple hash prefixes" do
    source = Solargraph::Source.load_string(%(
      ##
      # one
      # two
      class Foo; end
    ))
    node = source.node_at(4, 7)
    comments = source.comments_for(node)
    expect(comments.lines.map(&:chomp)).to eq(['one', 'two'])
  end

  it 'does not include inner comments' do
    source = Solargraph::Source.load_string(%(
      # included
      class Foo
        # ignored
      end
    ))
    node = source.node_at(2, 6)
    comments = source.comments_for(node)
    expect(comments).to include('included')
    expect(comments).not_to include('ignored')
  end

  it 'handles long squiggly heredocs' do
    source = Solargraph::Source.load('spec/fixtures/long_squiggly_heredoc.rb')
    expect(source.string_ranges).not_to be_empty
  end

  it 'handles string array substitutions' do
    source = Solargraph::Source.load_string(
      '%W[array of words #{\'with a substitution\'}]'
    )
    expect(source.string_ranges.length).to eq(4)
  end

  it 'handles errors in docstrings' do
    # YARD has a known problem with empty @overload tags
    comments = "@overload\n@return [String]"
    expect { Solargraph::Source.parse_docstring(comments) }.not_to raise_error
  end
end
