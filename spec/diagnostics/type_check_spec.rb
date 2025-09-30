describe Solargraph::Diagnostics::TypeCheck do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'detects defined return types' do
    source = Solargraph::Source.load_string(%(
      # @return [String]
      def foo
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always').diagnose(source, api_map)
    expect(result).to be_empty
  end

  it 'detects missing return types' do
    source = Solargraph::Source.load_string(%(
      def foo
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always', 'strong').diagnose(source, api_map)
    expect(result.length).to eq(1)
    expect(result[0][:message]).to include('foo')
  end

  it 'detects defined parameter types' do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      # @return [String]
      def foo(bar)
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always').diagnose(source, api_map)
    expect(result).to be_empty
  end

  it 'detects missing parameter types' do
    source = Solargraph::Source.load_string(%(
      # @return [String]
      def foo(bar)
        'foo'
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always', 'strong').diagnose(source, api_map)
    expect(result.length).to eq(1)
    expect(result[0][:message]).to include('bar')
  end

  it 'detects return types from superclasses' do
    source = Solargraph::Source.load_string(%(
      class First
        # @return [String]
        def foo
        end
      end
      class Second < First
        def foo
        end
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always').diagnose(source, api_map)
    expect(result).to be_empty
  end

  it 'detects parameter types from superclasses' do
    source = Solargraph::Source.load_string(%(
      class First
        # @param bar [String]
        # @return [String]
        def foo bar
        end
      end
      class Second < First
        def foo bar
        end
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always').diagnose(source, api_map)
    expect(result).to be_empty
  end

  it 'works with optional and keyword arguments' do
    source = Solargraph::Source.load_string(%(
      # @param bar [String]
      # @param baz [String]
      # @return [String]
      def foo(bar = 'bar', baz: 'baz')
      end
    ))
    api_map.map source
    result = Solargraph::Diagnostics::TypeCheck.new('always').diagnose(source, api_map)
    expect(result).to be_empty
  end
end
