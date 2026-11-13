# frozen_string_literal: true

# #call_type yields each receiver a call dispatches to with its pins, and
# combines what the block gives for each into the call's type.
describe Solargraph::ComplexType do
  let(:api_map) { Solargraph::ApiMap.new }

  # The type each receiver's pins return
  let(:return_types) { ->(_receiver, pins) { described_class.new(pins.map(&:return_type)) } }

  describe 'UniqueType#call_type' do
    it 'yields itself with its pins and answers with the block result' do
      type = described_class.parse('::String').items.first
      yielded = []
      result = type.call_type('upcase', api_map) do |receiver, pins|
        yielded << [receiver.rooted_tags, pins.map(&:path)]
        described_class.parse('::Symbol')
      end
      expect([yielded, result.rooted_tags]).to eq([[['::String', ['String#upcase']]], '::Symbol'])
    end

    it 'yields only the highest-precedence definition' do
      api_map.map Solargraph::Source.load_string(%(
        class Sup
          def foo; end
        end
        class Sub < Sup
          def foo; end
        end
      ), 'test.rb')
      type = described_class.parse('::Sub').items.first
      yielded = []
      type.call_type('foo', api_map) { |_receiver, pins| yielded.concat(pins.map(&:path)) }
      expect(yielded).to eq(['Sub#foo'])
    end

    it 'answers undefined without yielding when the type does not resolve the method' do
      type = described_class.parse('::String').items.first
      expect(type.call_type('frobnicate', api_map) { raise 'yielded' }).to be_undefined
    end
  end

  describe '#call_type' do
    it 'combines the result for each member of a union' do
      type = described_class.parse('::String', '::Integer')
      expect(type.call_type('to_s', api_map) { |receiver, _pins| receiver }.rooted_tags).to eq('::String, ::Integer')
    end

    it 'skips a member that does not resolve the method under loose unions' do
      type = described_class.parse('::String', '::Integer')
      expect(type.call_type('upcase', api_map, &return_types).rooted_tags).to eq('::String')
    end

    it 'answers undefined without yielding when a member does not resolve the method and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      type = described_class.parse('::String', '::Integer')
      expect(type.call_type('upcase', strict_map) { raise 'yielded' }).to be_undefined
    end

    it 'answers undefined when the call on a member that resolves the method is undefined' do
      type = described_class.parse('::String', '::Integer')
      result = type.call_type('to_s', api_map) do |receiver, _pins|
        receiver.rooted_tags == '::String' ? described_class::UNDEFINED : receiver
      end
      expect(result).to be_undefined
    end

    it 'orders nil last' do
      type = described_class.parse('nil', '::String')
      expect(type.call_type('to_s', api_map) { |receiver, _pins| receiver }.rooted_tags).to eq('::String, nil')
    end
  end
end
