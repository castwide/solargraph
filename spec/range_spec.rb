# frozen_string_literal: true

describe Solargraph::Range do
  def parse source
    Solargraph::Parser.parse(source, 'file.rb', 0)
  end

  describe '.from_node' do
    it 'returns nil for a node with no location info' do
      node = Parser::AST::Node.new(:sym, [:foo])
      expect(described_class.from_node(node)).to be_nil
    end

    it 'returns a range for a parsed node' do
      node = parse('class Foo; end')
      range = described_class.from_node(node)
      expect(range).to be_a(described_class)
    end
  end

  describe '.from_node!' do
    it 'returns a range for a parsed node' do
      node = parse('class Foo; end')
      range = described_class.from_node!(node)
      expect(range).to be_a(described_class)
      expect(range.start).to eq(Solargraph::Position.new(0, 0))
    end

    it 'raises for a node with no location info' do
      node = Parser::AST::Node.new(:sym, [:foo])
      expect { described_class.from_node!(node) }.to raise_error(ArgumentError)
    end
  end
end
