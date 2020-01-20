describe Solargraph::TypeChecker::Checks do
  it 'validates simple core types' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('String')
    inf = Solargraph::ComplexType.parse('String')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'invalidates simple core types' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('String')
    inf = Solargraph::ComplexType.parse('Integer')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(false)
  end

  it 'validates expected superclasses' do
    source = Solargraph::Source.load_string(%(
      class Sup; end
      class Sub < Sup; end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    sup = Solargraph::ComplexType.parse('Sup')
    sub = Solargraph::ComplexType.parse('Sub')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, sup, sub)
    expect(match).to be(true)
  end

  it 'invalidates inferred superclasses (expected must be super)' do
    source = Solargraph::Source.load_string(%(
      class Sup; end
      class Sub < Sup; end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    sup = Solargraph::ComplexType.parse('Sup')
    sub = Solargraph::ComplexType.parse('Sub')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, sub, sup)
    expect(match).to be(false)
  end

  it 'fuzzy matches arrays with parameters' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('Array')
    inf = Solargraph::ComplexType.parse('Array<String>')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'fuzzy matches sets with parameters' do
    source = Solargraph::Source.load_string("require 'set'")
    api_map = Solargraph::ApiMap.new
    api_map.map source
    exp = Solargraph::ComplexType.parse('Set')
    inf = Solargraph::ComplexType.parse('Set<String>')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'fuzzy matches hashes with parameters' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('Hash{ Symbol => String}')
    inf = Solargraph::ComplexType.parse('Hash')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'matches multiple types' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('String, Integer')
    inf = Solargraph::ComplexType.parse('String, Integer')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'matches multiple types out of order' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('String, Integer')
    inf = Solargraph::ComplexType.parse('Integer, String')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'invalidates inferred types missing from expected' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('String')
    inf = Solargraph::ComplexType.parse('String, Integer')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(false)
  end

  it 'matches nil' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('nil')
    inf = Solargraph::ComplexType.parse('nil')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'validates classes with expected superclasses' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('Class<Object>')
    inf = Solargraph::ComplexType.parse('Class<String>')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end

  it 'validates parameterized classes with expected Class' do
    api_map = Solargraph::ApiMap.new
    exp = Solargraph::ComplexType.parse('Class<String>')
    inf = Solargraph::ComplexType.parse('Class')
    match = Solargraph::TypeChecker::Checks.types_match?(api_map, exp, inf)
    expect(match).to be(true)
  end
end
