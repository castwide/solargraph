# frozen_string_literal: true

describe Solargraph::ComplexType do
  let(:api_map) do
    Solargraph::ApiMap.new
  end

  it 'validates simple core types' do
    exp = described_class.parse('String')
    inf = described_class.parse('String')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'invalidates simple core types' do
    exp = described_class.parse('String')
    inf = described_class.parse('Integer')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(false)
  end

  it 'allows subtype skew if told' do
    exp = described_class.parse('Array<Integer>')
    inf = described_class.parse('Array<String>')
    match = inf.conforms_to?(api_map, exp, :method_call, [:allow_subtype_skew])
    expect(match).to be(true)
  end

  it 'allows covariant behavior in parameters of Array' do
    exp = described_class.parse('Array<Object>')
    inf = described_class.parse('Array<Integer>')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'does not allow contravariant behavior in parameters of Array' do
    exp = described_class.parse('Array<Integer>')
    inf = described_class.parse('Array<Object>')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(false)
  end

  it 'allows covariant behavior in key types of Hash' do
    exp = described_class.parse('Hash{Object => String}')
    inf = described_class.parse('Hash{Integer => String}')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'accepts valid tuple conformance' do
    exp = described_class.parse('Array(Integer, Integer)')
    inf = described_class.parse('Array(Integer, Integer)')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'rejects invalid tuple conformance' do
    exp = described_class.parse('Array(Integer, Integer)')
    inf = described_class.parse('Array(Integer, String)')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(false)
  end

  it 'allows empty params when specified' do
    exp = described_class.parse('Array(Integer, Integer)')
    inf = described_class.parse('Array')
    match = inf.conforms_to?(api_map, exp, :method_call, [:allow_empty_params])
    expect(match).to be(true)
  end

  it 'validates expected superclasses' do
    source = Solargraph::Source.load_string(%(
      class Sup; end
      class Sub < Sup; end
    ))
    api_map.map source
    sup = described_class.parse('Sup')
    sub = described_class.parse('Sub')
    match = sub.conforms_to?(api_map, sup, :method_call)
    expect(match).to be(true)
  end

  it 'handles singleton types compared against their literals' do
    pending 'https://github.com/castwide/solargraph/issues/1196'
    pending 'https://github.com/castwide/solargraph/pull/1223'
    exp = Solargraph::ComplexType::UniqueType.new('nil', rooted: true)
    inf = Solargraph::ComplexType::UniqueType.new('NilClass', rooted: true)
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  # it 'invalidates inferred superclasses (expected must be super)' do
  # # @todo This test might be invalid. There are use cases where inheritance
  # #   between inferred and expected classes should be acceptable in either
  # #   direction.
  # # source = Solargraph::Source.load_string(%(
  # #   class Sup; end
  # #   class Sub < Sup; end
  # # ))
  # # api_map.map source
  # # sup = described_class.parse('Sup')
  # # sub = described_class.parse('Sub')
  # # match = Solargraph::TypeChecker::Checks.types_match?(api_map, sub, sup)
  # # expect(match).to be(false)
  # end

  it 'fuzzy matches arrays with parameters' do
    exp = described_class.parse('Array')
    inf = described_class.parse('Array<String>')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'fuzzy matches sets with parameters' do
    source = Solargraph::Source.load_string("require 'set'")
    source_map = Solargraph::SourceMap.map(source)
    api_map.catalog Solargraph::Bench.new(source_maps: [source_map], external_requires: ['set'])
    exp = described_class.parse('Set')
    inf = described_class.parse('Set<String>')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'fuzzy matches hashes with parameters' do
    exp = described_class.parse('Hash{ Symbol => String}')
    inf = described_class.parse('Hash')
    match = inf.conforms_to?(api_map, exp, :method_call, [:allow_empty_params])
    expect(match).to be(true)
  end

  it 'matches multiple types' do
    exp = described_class.parse('String, Integer')
    inf = described_class.parse('String, Integer')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'matches multiple types out of order' do
    exp = described_class.parse('String, Integer')
    inf = described_class.parse('Integer, String')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'invalidates inferred types missing from expected' do
    exp = described_class.parse('String')
    inf = described_class.parse('String, Integer')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(false)
  end

  it 'matches nil' do
    exp = described_class.parse('nil')
    inf = described_class.parse('nil')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'validates classes with expected superclasses' do
    exp = described_class.parse('Class<Object>')
    inf = described_class.parse('Class<String>')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  it 'validates generic classes with expected Class' do
    inf = described_class.parse('Class<String>')
    exp = described_class.parse('Class')
    match = inf.conforms_to?(api_map, exp, :method_call)
    expect(match).to be(true)
  end

  context 'with invariant matching' do
    it 'rejects String matching an Object' do
      inf = described_class.parse('String')
      exp = described_class.parse('Object')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :invariant)
      expect(match).to be(false)
    end

    it 'rejects Object matching an String' do
      inf = described_class.parse('Object')
      exp = described_class.parse('String')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :invariant)
      expect(match).to be(false)
    end

    it 'accepts String matching a String' do
      inf = described_class.parse('String')
      exp = described_class.parse('String')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :invariant)
      expect(match).to be(true)
    end
  end

  context 'with contravariant matching' do
    it 'rejects String matching an Objet' do
      inf = described_class.parse('String')
      exp = described_class.parse('Object')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :contravariant)
      expect(match).to be(false)
    end

    it 'accepts Object matching an String' do
      inf = described_class.parse('Object')
      exp = described_class.parse('String')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :contravariant)
      expect(match).to be(true)
    end

    it 'accepts String matching a String' do
      inf = described_class.parse('String')
      exp = described_class.parse('String')
      match = inf.conforms_to?(api_map, exp, :method_call, variance: :contravariant)
      expect(match).to be(true)
    end
  end

  context 'with an inheritence relationship' do
    let(:source) do
      Solargraph::Source.load_string(%(
        class Sup; end
        class Sub < Sup; end
      ))
    end
    let(:sup) { described_class.parse('Sup') }
    let(:sub) { described_class.parse('Sub') }

    before do
      api_map.map source
    end

    it 'validates inheritance in one way' do
      match = sub.conforms_to?(api_map, sup, :method_call, [:allow_reverse_match])
      expect(match).to be(true)
    end

    it 'validates inheritance the other way' do
      match = sup.conforms_to?(api_map, sub, :method_call, [:allow_reverse_match])
      expect(match).to be(true)
    end
  end

  context 'with RBS interface types' do
    it 'structurally validates a type that satisfies the interface, without any rule' do
      exp = described_class.parse('Hash::_Key')
      inf = described_class.parse('Symbol')
      match = inf.conforms_to?(api_map, exp, :method_call)
      expect(match).to be(true)
    end

    it 'structurally invalidates a type that does not satisfy the interface, even with allow_unmatched_interface' do
      exp = described_class.parse('_ToAry')
      inf = described_class.parse('Integer')
      match = inf.conforms_to?(api_map, exp, :method_call, [:allow_unmatched_interface])
      expect(match).to be(false)
    end

    it 'rejects a type that does not satisfy the interface when the rule is absent' do
      exp = described_class.parse('_ToAry')
      inf = described_class.parse('Integer')
      match = inf.conforms_to?(api_map, exp, :method_call)
      expect(match).to be(false)
    end

    it 'validates a type that satisfies the interface via a core fill include' do
      exp = described_class.parse('_ToAry')
      inf = described_class.parse('Array')
      match = inf.conforms_to?(api_map, exp, :method_call)
      expect(match).to be(true)
    end

    it 'falls back to allow_unmatched_interface when the interface pin cannot be found' do
      exp = described_class::UniqueType.new('_NoSuchInterface', rooted: true)
      inf = described_class.parse('Integer')
      expect(inf.conforms_to?(api_map, exp, :method_call, [:allow_unmatched_interface])).to be(true)
      expect(inf.conforms_to?(api_map, exp, :method_call)).to be(false)
    end

    it 'rejects a same-named method with the wrong return type' do
      pending 'https://github.com/castwide/solargraph/issues/1267'
      source = Solargraph::Source.load_string(%(
        class BadToAry
          # @return [String]
          def to_ary
            'not an array'
          end
        end
      ))
      api_map.map source
      exp = described_class.parse('_ToAry')
      inf = described_class.parse('BadToAry')
      match = inf.conforms_to?(api_map, exp, :method_call)
      expect(match).to be(false)
    end

    it 'rejects a same-named method with the wrong arity' do
      pending 'https://github.com/castwide/solargraph/issues/1267'
      source = Solargraph::Source.load_string(%(
        class BadKey
          def eql?
            true
          end

          def hash
            1
          end
        end
      ))
      api_map.map source
      exp = described_class.parse('Hash::_Key')
      inf = described_class.parse('BadKey')
      match = inf.conforms_to?(api_map, exp, :method_call)
      expect(match).to be(false)
    end
  end

  context 'with inheritance relationship in allow_reverse_match mode' do
    let(:api_map) { Solargraph::ApiMap.new }
    let(:sup) { described_class.parse('String') }
    let(:sub) { described_class.parse('Array') }

    it 'conforms one way' do
      match = sub.conforms_to?(api_map, sup, :method_call, [:allow_reverse_match])
      expect(match).to be(false)
    end

    it 'conforms the other way' do
      match = sup.conforms_to?(api_map, sub, :method_call, [:allow_reverse_match])
      expect(match).to be(false)
    end
  end
end
