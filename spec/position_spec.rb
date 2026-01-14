describe Solargraph::Position do
  it "normalizes arrays into positions" do
    pos = Solargraph::Position.normalize([0, 1])
    expect(pos).to be_a(Solargraph::Position)
    expect(pos.line).to eq(0)
    expect(pos.column).to eq(1)
  end

  it "returns original positions when normalizing" do
    orig = Solargraph::Position.new(0, 1)
    norm = Solargraph::Position.normalize(orig)
    expect(orig).to be(norm)
  end

  it 'finds offset from position' do
    text = "\n      class Foo\n        def bar baz, boo = 'boo'\n        end\n      end\n    "
    expect(Solargraph::Position.to_offset(text, Solargraph::Position.new(0, 0))).to eq(0)
    expect(Solargraph::Position.to_offset(text, Solargraph::Position.new(0, 4))).to eq(4)
    expect(Solargraph::Position.to_offset(text, Solargraph::Position.new(2, 12))).to eq(29)
    expect(Solargraph::Position.to_offset(text, Solargraph::Position.new(2, 27))).to eq(44)
    expect(Solargraph::Position.to_offset(text, Solargraph::Position.new(3, 8))).to eq(58)
  end

  it 'constructs position from offset' do
    text = "\n      class Foo\n        def bar baz, boo = 'boo'\n        end\n      end\n    "
    expect(Solargraph::Position.from_offset(text, 0)).to eq(Solargraph::Position.new(0, 0))
    expect(Solargraph::Position.from_offset(text, 4)).to eq(Solargraph::Position.new(1, 3))
    expect(Solargraph::Position.from_offset(text, 29)).to eq(Solargraph::Position.new(2, 12))
    expect(Solargraph::Position.from_offset(text, 44)).to eq(Solargraph::Position.new(2, 27))
  end

  it "raises an error for objects that cannot be normalized" do
    expect {
      Solargraph::Position.normalize('0, 1')
    }.to raise_error(ArgumentError)
  end

  it 'avoids fencepost errors' do
    text = "      class Foo\n        def bar baz, boo = 'boo'\n        end\n      end\n    "
    offset = Solargraph::Position.to_offset(text, Solargraph::Position.new(3, 6))
    expect(offset).to eq(67)
  end

  it 'avoids fencepost errors with multiple blank lines' do
    text = "      class Foo\n        def bar baz, boo = 'boo'\n\n        end\n      end\n    "
    offset = Solargraph::Position.to_offset(text, Solargraph::Position.new(4, 6))
    expect(offset).to eq(68)
  end
end
