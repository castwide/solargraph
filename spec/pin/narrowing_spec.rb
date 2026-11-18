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

  describe '.variables' do
    it 'keeps variables and drops expression narrowings' do
      map = Solargraph::SourceMap.load_string(%(
        # @param h [Hash{Symbol => Integer}]
        def foo h
          return 0 unless h.key?(:a)
          h[:a]
        end
      ), 'test.rb')
      expect(map.locals.map(&:class)).to include(Solargraph::Pin::ExpressionNarrowing)
      expect(described_class.variables(map.locals).map(&:name)).to eq(['h'])
    end
  end
end
