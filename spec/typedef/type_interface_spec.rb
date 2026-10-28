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

  describe '#candidate_methods_from' do
    it 'offers the instance methods of a concrete type' do
      pins = concrete('::String').candidate_methods_from(api_map, '', false)
      expect(pins.map(&:path)).to include('String#upcase')
    end

    it 'offers the class methods of the class a Class type names' do
      pins = concrete('Class', union(concrete('::String'))).candidate_methods_from(api_map, '', false)
      expect(pins.map(&:path)).to include('String.try_convert')
    end

    it 'offers the class methods of a class named by a bare path' do
      pins = concrete('Class', '::String').candidate_methods_from(api_map, '', false)
      expect(pins.map(&:path)).to include('String.try_convert')
    end

    it 'offers the instance methods of Class for a bare Class' do
      pins = concrete('::Class').candidate_methods_from(api_map, '', false)
      expect(pins.map(&:path)).to include('Class#new')
    end

    it 'offers nothing for an undefined type' do
      expect(Solargraph::Typedef::Concrete::UNDEFINED.candidate_methods_from(api_map, '', false)).to eq([])
    end

    it 'pools the methods of every member of a union' do
      pins = union(concrete('::String'), concrete('::Symbol')).candidate_methods_from(api_map, '', false)
      expect(pins.map(&:path)).to include('String#upcase', 'Symbol#to_proc')
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

  describe '#method_stack_pins' do
    it 'answers with the first pin of the method stack' do
      expect(concrete('::String').method_stack_pins('upcase', api_map).map(&:path)).to eq(['String#upcase'])
    end

    it 'looks up class methods on a Class type' do
      pins = concrete('Class', union(concrete('::String'))).method_stack_pins('try_convert', api_map)
      expect(pins.map(&:path)).to eq(['String.try_convert'])
    end

    it 'answers nil when the type does not define the method' do
      expect(concrete('::String').method_stack_pins('frobnicate', api_map)).to be_nil
    end

    it 'gathers the pins of every member of a union' do
      pins = union(concrete('::String'), concrete('::Symbol')).method_stack_pins('upcase', api_map)
      expect(pins.map(&:path)).to eq(['String#upcase', 'Symbol#upcase'])
    end

    it 'keeps the pins of the members that resolve under loose unions' do
      pins = union(concrete('::String'), concrete('::Integer')).method_stack_pins('upcase', api_map)
      expect(pins.map(&:path)).to eq(['String#upcase'])
    end

    it 'answers nil when a member does not resolve and unions are strict' do
      strict_map = Solargraph::ApiMap.new(loose_unions: false)
      expect(union(concrete('::String'), concrete('::Integer')).method_stack_pins('upcase', strict_map)).to be_nil
    end

    it 'answers nil when no member of a union resolves' do
      expect(union(concrete('::String'), concrete('::Integer')).method_stack_pins('frobnicate', api_map)).to be_nil
    end
  end
end
