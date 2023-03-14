if defined?(RubyVM::AbstractSyntaxTree)
  describe RubyVM::AbstractSyntaxTree do
    it "parses node by byteoffset" do
      node = RubyVM::AbstractSyntaxTree.parse("𐐀 + 𐐀").children[2]
      expect(node.last_column).to eq(11)
    end
  end
end
