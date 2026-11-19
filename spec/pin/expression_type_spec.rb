# frozen_string_literal: true

describe Solargraph::Pin::ExpressionType do
  it 'is an expression type whose expression is the variable name' do
    map = Solargraph::SourceMap.load_string(%(
      x = 'string'
      x
    ), 'test.rb')
    variable = map.locals.find { |pin| pin.name == 'x' }
    expect(variable).to be_a(described_class)
    expect(variable.expression).to eq('x')
    expect(variable.presence).to be_a(Solargraph::Range)
  end
end
