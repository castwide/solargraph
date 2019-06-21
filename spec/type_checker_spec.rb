describe Solargraph::TypeChecker do
  it 'validates tagged return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [String]
        def bar; end
      end
    ), 'test.rb')
    expect(checker.return_type_problems).to be_empty
  end

  it 'reports untagged return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar; end
      end
    ), 'test.rb')
    expect(checker.return_type_problems).to be_one
  end

  it 'reports unresolved return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [UndefinedClass]
        def bar; end
      end
    ), 'test.rb')
    expect(checker.return_type_problems).to be_one
    expect(checker.return_type_problems.first.message).to include('unresolved @return type')
  end

  it 'validates tagged param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param baz [Integer]
        def bar(baz); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'reports untagged param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar(baz); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_one
  end

  it 'validates undefined params with kwrestargs' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param foo [String]
        def bar(**baz); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'validates tagged kwoptarg params' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param foo [String]
        def bar(foo: ''); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'validates tagged kwarg params' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param foo [String]
        def bar(foo:); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'reports unresolved param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param foo [UndefinedClass]
        def bar(foo:); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_one
    expect(checker.param_type_problems.first.message).to include('unresolved @param type')
  end

  it 'validates untagged restarg params' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar(*args); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'validates untagged kwrestarg params' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        def bar(**args); end
      end
    ), 'test.rb')
    expect(checker.param_type_problems).to be_empty
  end

  it 'reports param tags without defined parameters' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @param baz [String]
        def bar; end
      end
    ))
    expect(checker.param_type_problems).to be_one
    expect(checker.param_type_problems.first.message).to include('unknown @param baz')    
  end

  it 'validates literal strings' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [String]
        def bar
          'bar'
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty
  end

  it 'reports mismatched literal strings' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [Array]
        def bar
          'bar'
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_one
  end

  it 'ignores undefined return types from external libraries' do
    # This test uses Benchmark because Benchmark.measure#time is known to
    # return a Float but it's not tagged in the stdlib yardoc.
    checker = Solargraph::TypeChecker.load_string(%(
      require 'benchmark'
      class Foo
        # @return [Float]
        def bar
          Benchmark.measure{}.time
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty
  end

  it 'reports unresolved signatures' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [Float]
        def bar
          undocumented_method
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_one
  end

  it 'validates parameterized return types with unparameterized arrays' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [Array<String>]
        def bar
          []
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty
  end

  it 'validates parameterized return types with unparameterized hashes' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [Hash{String => Integer}]
        def bar
          {}
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty
  end

  it 'validates subclasses of return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Sup; end
      class Sub < Sup
        # @return [Sup]
        def foo
          Sub.new
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty   
  end

  it 'reports superclasses of return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Sup; end
      class Sub < Sup
        # @return [Sub]
        def foo
          Sup.new
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_one
    expect(checker.strict_type_problems.first.message).to include('does not match inferred type')
  end

  it 'validates parameterized subclasses of return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Sup; end
      class Sub < Sup
        # @return [Class<Sup>]
        def foo
          Sub
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty   
  end

  it 'reports parameterized subclasses of return types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Sup; end
      class Sub < Sup
        # @return [Class<Sub>]
        def foo
          Sup
        end
      end
    ), 'test.rb')
    expect(checker.strict_type_problems).to be_one
    expect(checker.strict_type_problems.first.message).to include('does not match inferred type')
  end

  it 'validates subclass arguments of param types' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Sup
        # @param other [Sup]
        # @return [void]
        def take(other); end
      end
      class Sub < Sup; end
      Sup.new.take(Sub.new)
      ), 'test.rb')
    expect(checker.strict_type_problems).to be_empty
  end

  it 'validates attr_writer parameters' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [String]
        attr_accessor :bar
      end
      Foo.new.bar = 'hello'
    ))
    expect(checker.strict_type_problems).to be_empty
  end

  it 'reports invalid attr_writer parameters' do
    checker = Solargraph::TypeChecker.load_string(%(
      class Foo
        # @return [Integer]
        attr_accessor :bar
      end
      Foo.new.bar = 'hello'
    ))
    expect(checker.strict_type_problems).to be_one
  end

  it 'does not raise errors checking unparsed sources' do
    checker = Solargraph::TypeChecker.load_string(%(
      foo{
    ))
    expect {
      checker.param_type_problems
      checker.return_type_problems
      checker.strict_type_problems
    }.not_to raise_error
  end
end
