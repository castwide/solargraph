describe Solargraph::TypeChecker do
  it 'validates tagged return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [String]
        def bar; end
      end
    ))
    expect(checker.return_type_problems).to be_empty
  end

  it 'reports untagged return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar; end
      end
    ))
    expect(checker.return_type_problems).not_to be_empty
  end

  it 'validates tagged param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param baz [Integer]
        def bar(baz); end
      end
    ))
    expect(checker.param_type_problems).to be_empty
  end

  it 'reports untagged param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar(baz); end
      end
    ))
    expect(checker.param_type_problems).not_to be_empty
  end
end
