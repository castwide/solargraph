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
end
