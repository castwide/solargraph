# frozen_string_literal: true

describe Solargraph::Position do
  it 'normalizes arrays into positions' do
    pos = described_class.normalize([0, 1])
    expect(pos).to be_a(described_class)
    expect(pos.line).to eq(0)
    expect(pos.column).to eq(1)
  end

  it 'returns original positions when normalizing' do
    orig = described_class.new(0, 1)
    norm = described_class.normalize(orig)
    expect(orig).to be(norm)
  end

  it 'finds offset from position' do
    text = "\n      class Foo\n        def bar baz, boo = 'boo'\n        end\n      end\n    "
    expect(described_class.to_offset(text, described_class.new(0, 0))).to eq(0)
    expect(described_class.to_offset(text, described_class.new(0, 4))).to eq(4)
    expect(described_class.to_offset(text, described_class.new(2, 12))).to eq(29)
    expect(described_class.to_offset(text, described_class.new(2, 27))).to eq(44)
  end

  it 'constructs position from offset' do
    text = "\n      class Foo\n        def bar baz, boo = 'boo'\n        end\n      end\n    "
    expect(described_class.from_offset(text, 0)).to eq(described_class.new(0, 0))
    expect(described_class.from_offset(text, 4)).to eq(described_class.new(1, 3))
    expect(described_class.from_offset(text, 29)).to eq(described_class.new(2, 12))
    expect(described_class.from_offset(text, 44)).to eq(described_class.new(2, 27))
  end

  it 'raises an error for objects that cannot be normalized' do
    expect do
      described_class.normalize('0, 1')
    end.to raise_error(ArgumentError)
  end
end
