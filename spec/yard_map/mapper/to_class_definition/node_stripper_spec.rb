# frozen_string_literal: true

describe Solargraph::YardMap::Mapper::ToClassDefinition::NodeStripper do
  let(:location) { Solargraph::Location.new('foo.rb', Solargraph::Range.from_to(0, 0, 0, 0)) }
  let(:stripper) { described_class.new(location) }
  let(:node) { Solargraph::Source.load_string('1 + 1').node }

  describe '#scrub_array (private)' do
    it 'blanks a plain array of nodes to a frozen empty array' do
      result = stripper.send(:scrub_array, :@some_nodes, [node, node])
      expect(result).to eq([])
      expect(result).to be_frozen
    end

    it 'nils out @mass_assignment instead of leaving a malformed pair behind' do
      result = stripper.send(:scrub_array, :@mass_assignment, [node, 0, false])
      expect(result).to be_nil
    end
  end
end
