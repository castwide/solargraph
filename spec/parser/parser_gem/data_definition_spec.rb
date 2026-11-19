# frozen_string_literal: true

describe Solargraph::Parser::ParserGem::NodeProcessors::DataDefinition do
  describe 'node wrappers' do
    it 'names a data class assigned to a scoped constant' do
      source = Solargraph::SourceMap.load_string(%(
        Outer::Foo = Data.define(:bar)
      ), 'test.rb')

      expect(source.pins.map(&:path)).to include('Outer::Foo#bar')
    end

    it 'returns the class body from a data definition' do
      node = Solargraph::Parser.parse("class Foo < Data.define(:bar)\n  def baz; end\nend")
      body = Solargraph::Parser::ParserGem::NodeProcessors::DataDefinition::DataDefintionNode.new(node).body_node

      expect(body.type).to eq(:def)
    end

    it 'returns the assigned value from a data assignment' do
      node = Solargraph::Parser.parse("Foo = Data.define(:bar) do\n  def baz; end\nend")
      body = Solargraph::Parser::ParserGem::NodeProcessors::DataDefinition::DataAssignmentNode.new(node).body_node

      expect(body.type).to eq(:block)
    end
  end
end
