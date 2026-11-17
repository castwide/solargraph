# frozen_string_literal: true

describe Solargraph::Pin::Narrowing do
  it 'is a variable narrowing whose subject is the variable name' do
    map = Solargraph::SourceMap.load_string(%(
      x = 'string'
      x
    ), 'test.rb')
    variable = map.locals.find { |pin| pin.name == 'x' }
    expect(variable).to be_a(described_class)
    expect(variable.subject).to eq('x')
    expect(variable.presence).to be_a(Solargraph::Range)
  end
end
