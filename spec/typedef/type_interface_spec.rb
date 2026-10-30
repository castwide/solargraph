# frozen_string_literal: true

# The Typedef classes answer the questions lib/ asks of any
# Solargraph::Type the same way ComplexType and UniqueType do.
describe Solargraph::Type do
  let(:api_map) { Solargraph::ApiMap.new }

  # @param name [String]
  # @param params [Array<Solargraph::Type>]
  def concrete name, *params
    Solargraph::Typedef::Concrete.new(Solargraph::Typedef.tokenize(name), *params)
  end

  # @param types [Array<Solargraph::Type>]
  def union *types
    Solargraph::Typedef::Union.new(types)
  end

  describe '#reachable_methods' do
    it 'offers the instance methods of a concrete type' do
      pins = concrete('::String').reachable_methods(api_map)
      expect(pins.map(&:path)).to include('String#upcase')
    end

    it 'offers the class methods of the class a Class type names' do
      pins = concrete('Class', union(concrete('::String'))).reachable_methods(api_map)
      expect(pins.map(&:path)).to include('String.try_convert')
    end

    it 'offers the class methods of a class named by a bare path' do
      pins = concrete('Class', '::String').reachable_methods(api_map)
      expect(pins.map(&:path)).to include('String.try_convert')
    end

    it 'offers the instance methods of Class for a bare Class' do
      pins = concrete('::Class').reachable_methods(api_map)
      expect(pins.map(&:path)).to include('Class#new')
    end

    it 'offers nothing for an undefined type' do
      expect(Solargraph::Typedef::Concrete::UNDEFINED.reachable_methods(api_map)).to eq([])
    end

    it 'pools the methods of every member of a union' do
      pins = union(concrete('::String'), concrete('::Symbol')).reachable_methods(api_map)
      expect(pins.map(&:path)).to include('String#upcase', 'Symbol#to_proc')
    end
  end

  describe '#combine_via' do
    # Keeps a pair whose sides read the same, and unions any other pair
    def combine left, right
      left.combine_via(right) { |mine, theirs| mine.to_s == theirs.to_s ? mine : union(mine, theirs) }
    end

    it 'pairs a concrete type with the whole of the other' do
      type = concrete('A')
      other = union(concrete('B'), concrete('C'))
      expect(type.combine_via(other) { |mine, theirs| [mine, theirs] }).to eq([type, other])
    end

    it 'matches the members both unions carry whatever order they appear in' do
      result = combine(union(concrete('A'), concrete('B')), union(concrete('B'), concrete('A')))
      expect(result.to_s).to eq('A | B')
    end

    it 'zips up the members left over once the shared ones are matched' do
      result = combine(union(concrete('A'), concrete('C')), union(concrete('D'), concrete('A')))
      expect(result.to_s).to eq('A | C | D')
    end

    it 'hands the whole remainder of the longer side to the last member of the shorter' do
      result = combine(union(concrete('A'), concrete('B'), concrete('C')), union(concrete('A'), concrete('D')))
      expect(result.to_s).to eq('A | B | C | D')
    end

    it 'sets a lone concrete type against the whole union' do
      expect(combine(union(concrete('A'), concrete('B')), concrete('A')).to_s).to eq('A | B')
    end

    it 'gathers a lone member on either side into one pair' do
      expect(combine(union(concrete('A')), concrete('A')).to_s).to eq('A')
    end
  end

  describe '#order_nil_last' do
    it 'moves nil to the end of a union and keeps the other members in order' do
      type = union(concrete('nil'), concrete('String'), concrete('Integer'))
      expect(type.order_nil_last.to_s).to eq('String | Integer | nil')
    end

    it 'leaves a concrete type as it is' do
      type = concrete('nil')
      expect(type.order_nil_last).to be(type)
    end
  end

  describe '#qualify_parts' do
    it 'hands a concrete type to the block as itself' do
      type = concrete('Foo')
      expect(type.qualify_parts { |part| [part] }).to eq([type])
    end

    it 'rebuilds a union from what the block returns for each member' do
      result = union(concrete('Foo'), concrete('Bar')).qualify_parts { |part| concrete("::Outer::#{part}") }
      expect(result.to_s).to eq('Outer::Foo | Outer::Bar')
    end

    it 'is nil when the block cannot resolve any one member' do
      result = union(concrete('Foo'), concrete('Bar')).qualify_parts { |part| part.to_s == 'Bar' ? nil : part }
      expect(result).to be_nil
    end
  end

  describe '#reachable_method_stack' do
    it 'answers with the method stack' do
      expect(concrete('::String').reachable_method_stack(api_map, 'upcase').map(&:path)).to eq(['String#upcase'])
    end

    it 'looks up class methods on a Class type' do
      pins = concrete('Class', union(concrete('::String'))).reachable_method_stack(api_map, 'try_convert')
      expect(pins.map(&:path)).to eq(['String.try_convert'])
    end

    it 'answers empty when the type does not define the method' do
      expect(concrete('::String').reachable_method_stack(api_map, 'frobnicate')).to eq([])
    end

    it 'gathers the pins of every member of a union' do
      pins = union(concrete('::String'), concrete('::Symbol')).reachable_method_stack(api_map, 'upcase')
      expect(pins.map(&:path)).to eq(['String#upcase', 'Symbol#upcase'])
    end

    it 'keeps the pins of the members that resolve under loose unions' do
      pins = union(concrete('::String'), concrete('::Integer')).reachable_method_stack(api_map, 'upcase')
      expect(pins.map(&:path)).to eq(['String#upcase'])
    end

    it 'answers empty when a member does not resolve and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      expect(union(concrete('::String'), concrete('::Integer')).reachable_method_stack(strict_map, 'upcase')).to eq([])
    end

    it 'answers empty when no member of a union resolves' do
      expect(union(concrete('::String'), concrete('::Integer')).reachable_method_stack(api_map, 'frobnicate')).to eq([])
    end
  end

  describe '#call_type' do
    it 'yields a concrete type with its pins and answers with the block result' do
      yielded = []
      result = concrete('::String').call_type('upcase', api_map) do |receiver, pins|
        yielded << [receiver.to_s, pins.map(&:path)]
        concrete('::Symbol')
      end
      expect([yielded, result.to_s]).to eq([[['String', ['String#upcase']]], 'Symbol'])
    end

    it 'answers undefined without yielding when a concrete type does not resolve the method' do
      expect(concrete('::String').call_type('frobnicate', api_map) { raise 'yielded' }).to be_undefined
    end

    it 'combines the result for each member of a union' do
      result = union(concrete('::String'), concrete('::Integer')).call_type('to_s', api_map) { |receiver, _| receiver }
      expect(result.to_s).to eq('String | Integer')
    end

    it 'skips a member that does not resolve the method under loose unions' do
      result = union(concrete('::String'), concrete('::Integer')).call_type('upcase', api_map) { |receiver, _| receiver }
      expect(result.to_s).to eq('String')
    end

    it 'answers undefined without yielding when a member does not resolve the method and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      result = union(concrete('::String'), concrete('::Integer')).call_type('upcase', strict_map) { raise 'yielded' }
      expect(result).to be_undefined
    end
  end
end
