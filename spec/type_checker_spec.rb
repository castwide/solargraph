describe Solargraph::TypeChecker do
#   it 'reports param tags without defined parameters' do
#     checker = Solargraph::TypeChecker.load_string(%(
#       class Foo
#         # @param baz [String]
#         def bar; end
#       end
#     ))
#     expect(checker.param_type_problems).to be_one
#     expect(checker.param_type_problems.first.message).to include('unknown @param baz')
#   end

#   it 'ignores undefined return types from external libraries' do
#     # @todo We're temporarily ignoring this test on Ruby 2.7. The Benchmark
#     #   library has been moved to an external gem. As a result, this checker
#     #   fails to identify the Benchmark module and emits a strict type error.
#     next if RUBY_VERSION.start_with?('2.7.')
#     # This test uses Benchmark because Benchmark.measure#time is known to
#     # return a Float but it's not tagged in the stdlib yardoc.
#     checker = Solargraph::TypeChecker.load_string(%(
#       require 'benchmark'
#       class Foo
#         # @return [Float]
#         def bar
#           Benchmark.measure{}.time
#         end
#       end
#     ), 'test.rb')
#     expect(checker.strict_type_problems).to be_empty
#   end

#   it 'reports unresolved signatures' do
#     checker = Solargraph::TypeChecker.load_string(%(
#       class Foo
#         # @return [Float]
#         def bar
#           undocumented_method
#         end
#       end
#     ), 'test.rb')
#     expect(checker.strict_type_problems).to be_one
#   end

  it 'does not raise errors checking unparsed sources' do
    expect {
      checker = Solargraph::TypeChecker.load_string(%(
        foo{
      ))
      checker.problems
    }.not_to raise_error
  end

#   it 'handles Hash#[]= with incorrect key parameter' do
#     checker = Solargraph::TypeChecker.load_string(%(
#       # @type [Hash{Symbol => Object}]
#       h = {}
#       # This should raise a problem. The key needs to be a Symbol.
#       h[100] = 'bar'
#     ))
#     expect(checker.strict_type_problems).to be_one
#     expect(checker.strict_type_problems.first.message).to include('Wrong parameter type')
#   end

#   it 'handles Hash#[]= with incorrect value parameter' do
#     checker = Solargraph::TypeChecker.load_string(%(
#       # @type [Hash{Symbol => Integer}]
#       h = {}
#       # This should raise a problem. The value needs to be an Integer.
#       h[:foo] = 'bar'
#     ))
#     expect(checker.strict_type_problems).to be_one
#     expect(checker.strict_type_problems.first.message).to include('Wrong parameter type')
#   end

#   it 'handles Hash#[]= with correct parameters' do
#     checker = Solargraph::TypeChecker.load_string(%(
#       # @type [Hash{Symbol => Integer}]
#       h = {}
#       h[:foo] = 100
#     ))
#     expect(checker.strict_type_problems).to be_empty
#   end
end
