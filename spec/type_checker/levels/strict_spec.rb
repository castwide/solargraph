describe Solargraph::TypeChecker do
  context 'strict level' do
    # @return [Solargraph::TypeChecker]
    def type_checker(code)
      Solargraph::TypeChecker.load_string(code, 'test.rb', :strict)
    end

    it 'handles compatible interfaces with self types on call' do
      checker = type_checker(%(
        # @param a [Enumerable<String>]
        def bar(a); end

        bar(['a'])
      ))
      expect(checker.problems).to be_empty
    end

    it 'complains on @!parse blocks too' do
      checker = type_checker(%(
      # @!parse
      #   class Foo
      #     # @return [Bar]
      #     def baz; end
      #   end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved return type Bar for Foo#baz')
    end

    it 'ignores method calls with inferred types' do
      checker = type_checker(%(
        String.new.upcase
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports method calls without inferred types' do
      checker = type_checker(%(
        unknown_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call')
      expect(checker.problems.first.message).not_to include('undefined')
    end

    it 'reports undefined method calls with defined roots' do
      checker = type_checker(%(
        String.new.not_a_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved call')
      expect(checker.problems.first.message).to include('String')
      expect(checker.problems.first.message).to include('not_a_method')
    end

    it 'ignores undefined method calls from external sources' do
      # @todo This test uses kramdown-parser-gfm because it's a gem dependency known to
      #   lack typed methods. A better test wouldn't depend on the state of
      #   vendored code.
      source_map = Solargraph::SourceMap.load_string(%(
        require 'kramdown-parser-gfm'
        Kramdown::Parser::GFM.undefined_call
      ), 'test.rb')
      api_map = Solargraph::ApiMap.load_with_cache('.', $stdout)
      api_map.catalog Solargraph::Bench.new(source_maps: [source_map], external_requires: ['kramdown-parser-gfm'])
      checker = Solargraph::TypeChecker.new('test.rb', api_map: api_map, level: :strict)
      expect(checker.problems).to be_empty
    end

    it 'validates existing param tags' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz)
            'test'
          end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'ignores missing optional arguments' do
      checker = type_checker(%(
        class Foo
          def bar *baz
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched argument types' do
      checker = type_checker(%(
        class Foo
          # @param baz [Integer]
          def bar(baz); end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports mismatched argument types in chained calls' do
      checker = type_checker(%(
        # @param baz [Integer]
        # @return [String]
        def bar(baz); "foo"; end
        bar('string').upcase
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports mismatched argument types in calls inside array literals' do
      checker = type_checker(%(
        # @param baz [Integer]
        # @return [String]
        def bar(baz); "foo"; end
        [ bar('string') ]
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports mismatched argument types in calls inside array literals used in a chain' do
      checker = type_checker(%(
        # @param baz [Integer]
        # @return [String]
        def bar(baz); "foo"; end
        [ bar('string') ].compact
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    xit 'complains about calling a private method from an illegal place'

    xit 'complains about calling a non-existent method'

    xit 'complains about inserting the wrong type into a tuple slot' do
      checker = type_checker(%(
        # @param a [::Solargraph::Fills::Tuple(String, Integer)]
        def foo(a)
          a[0] = :something
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Wrong argument type'])
    end

    it 'complains about dereferencing a non-existent tuple slot'

    it 'reports mismatched keyword arguments' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: 100
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports argument mismatches in mixed arguments and kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz, quz: ''
          end
        end
        Foo.new.bar 1, quz: 'two'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('baz')
    end

    it 'reports mismatches in multiple kwargs' do
      checker = type_checker(%(
        class Foo
          # @param baz [String]
          # @param quz [String]
          def bar baz: '', quz: ''
          end
        end
        Foo.new.bar quz: 100
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('quz')
    end

    it 'validates arguments that match duck type params' do
      checker = type_checker(%(
        class Foo
          # @param baz [#to_s]
          # @return [void]
          def bar(baz); end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports mismatched duck types' do
      checker = type_checker(%(
        class Foo
          # @param baz [#unknown_method]
          def bar baz: ''
          end
        end
        Foo.new.bar baz: String.new
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'reports mismatched kwrestargs' do
      checker = type_checker(%(
        class Foo
          # @param one [String]
          # @param two [Integer]
          def bar **baz
          end
        end
        Foo.new.bar one: 'one', two: 'two'
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('two')
    end

    it 'reports mismatched params in trailing optional hash parameters' do
      checker = type_checker(%(
        class Foo
          # @param named [String]
          def bar opts = {}
          end
        end
        Foo.new.bar named: 0
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
      expect(checker.problems.first.message).to include('named')
    end

    it 'reports untyped methods without inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            unknown_method
          end
        end
      ))
      expect(checker.problems.length).to eq(2)
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'ignores untyped methods with inferred types' do
      checker = type_checker(%(
        class Foo
          def bar
            Array.new
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'skips type inference for method macros' do
      checker = type_checker(%(
        # @!method bar
        #   @return [String]
        class Foo; end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports untyped attributes' do
      checker = type_checker(%(
        class Foo
          attr_reader :bar
        end
      ))
      expect(checker.problems).to be_one
      # @todo Maybe change the message to "missing @return tag"
      expect(checker.problems.first.message).to include('could not be inferred')
    end

    it 'validates attr_writer parameters' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          attr_accessor :bar
        end
        Foo.new.bar = 'hello'
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports invalid attr_writer parameters' do
      checker = type_checker(%(
        class Foo
          # @return [Integer]
          attr_accessor :bar
        end
        Foo.new.bar = 'hello'
      ))
      expect(checker.problems).to be_one
    end

    it 'reports arguments that do not match duck type params' do
      checker = type_checker(%(
        class Foo
          # @param baz [#upcase]
          # @return [void]
          def bar(baz); end
        end
        Foo.new.bar(100)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'validates complex parameters' do
      checker = type_checker(%(
        class Foo
          # @param baz [Hash, Array]
          # @return [void]
          def bar baz
          end
        end
        Foo.new.bar([1, 2])
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports arguments that do not match complex parameters' do
      checker = type_checker(%(
        class Foo
          # @param baz [Hash, Array]
          def bar baz
          end
        end
        Foo.new.bar('string')
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    # @todo Should this be tested at the strong level?
    it 'validates Hash#[]= with simple objects' do
      checker = type_checker(%(
        h = {}
        h['foo'] = 'bar'
        h[100] = []
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports incorrect arguments from superclass param tags' do
      checker = type_checker(%(
        class Foo
          # @param arg [String]
          def meth arg
          end
        end

        class Bar < Foo
          def meth arg
          end
        end

        # Error: arg should be a String
        Bar.new.meth(100)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'validates Boolean parameters' do
      checker = type_checker(%(
        class Foo
          # @param bool [Boolean]
          def bar bool
          end
        end

        Foo.new.bar(true)
        Foo.new.bar(false)
      ))
      expect(checker.problems).to be_empty
    end

    it 'invalidates incorrect Boolean parameters' do
      checker = type_checker(%(
        class Foo
          # @param bool [Boolean]
          def bar bool
          end
        end

        Foo.new.bar(1)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Wrong argument type')
    end

    it 'resolves Kernel methods in instance scopes' do
      checker = type_checker(%(
        class Foo
          # @return [void]
          def bar
            raise 'oops'
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports missing arguments' do
      checker = type_checker(%(
        class Foo
          def bar(baz)
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Not enough arguments')
    end

    it 'does not attempt to account for splats' do
      checker = type_checker(%(
        class Foo
          def bar(baz, bing)
          end

          def blah(args)
             bar *args
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'does not attempt to account for splats in arg counts' do
      checker = type_checker(%(
        class Foo
          def bar(baz, bing)
          end

          def blah(args)
             bar *args
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'does not attempt to account for types in splats' do
      checker = type_checker(%(
        class Foo
          # @param baz [Symbol]
          def bar(baz)
          end

          def blah(args = [:foo])
             bar(*args)
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports solo missing kwarg' do
      checker = type_checker(%(
        class Foo
          def bar(baz:)
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing keyword arguments')
    end

    it 'reports not enough kwargs' do
      checker = type_checker(%(
        class Foo
          def bar(foo:, baz:)
          end
        end
        Foo.new.bar(foo: 100)
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Missing keyword argument')
      expect(checker.problems.first.message).to include('baz')
    end

    it 'accepts passed kwargs' do
      checker = type_checker(%(
        class Foo
          def bar(baz:)
          end
        end
        Foo.new.bar(baz: 123)
      ))
      expect(checker.problems).to be_empty
    end

    it 'accepts multiple passed kwargs' do
      checker = type_checker(%(
        class Foo
          def bar(baz:, bing:)
          end
        end
        Foo.new.bar(baz: 123, bing: 456)
      ))
      expect(checker.problems).to be_empty
    end

    it 'requires strict return tags' do
      pending 'nil? support in flow sensitive typing'

      checker = type_checker(%(
        class Foo
          # The tag is [String] but the inference is [String, nil]
          #
          # @return [String]
          def bar
            false ? 'bar' : nil
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'requires strict return tags' do
      pending 'nil? support in flow sensitive typing'

      checker = type_checker(%(
        class Foo
          # The tag is [String] but the inference is [String, nil]
          #
          # @return [String]
          def bar
            true ? nil : 'bar'
          end
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'validates strict return tags' do
      checker = type_checker(%(
        class Foo
          # @return [String, nil]
          def bar
            false ? 'bar' : nil
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'Can infer through ||= with a begin+end' do
      checker = type_checker(%(
        def recipient
          @recipient ||= true ? "foo" : "bar"
        end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'validates kwoptargs without arguments' do
      checker = type_checker(%(
        class Foo
          def bar baz: ''
          end
        end
        Foo.new.bar
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unresolved constants' do
      checker = type_checker(%(
        NotReal
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved constant')
    end

    it 'reports unresolved nested constants' do
      checker = type_checker(%(
        String::NotReal
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved constant')
    end

    it 'skips validation of method calls for unresolved constants' do
      checker = type_checker(%(
        NotReal.not_a_method
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('Unresolved constant')
    end

    it 'validates included modules in types' do
      checker = type_checker(%(
        module Interface
        end
        class Host
          include Interface
        end
        # @type [Interface]
        host = Host.new
      ))
      expect(checker.problems).to be_empty
    end

    it 'invalidates modules not included in types' do
      checker = type_checker(%(
        module Interface
        end
        class Host
        end
        # @type [Interface]
        host = Host.new
      ))
      expect(checker.problems).to be_one
    end

    it 'ignores method aliases' do
      checker = type_checker(%(
        class Foo
          # @return [String]
          def bar
            'bar'
          end
          alias baz bar
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unknown method calls on local variables' do
      checker = type_checker(%(
        s = ''
        s.not_a_method
      ))
      expect(checker.problems).to be_one
    end

    it 'reports unknown method calls on instance variables' do
      checker = type_checker(%(
        class Foo
          def bar
            @string = 'string'
            @string.not_a_method
            @string.upcase
          end
        end
      ))
      expect(checker.problems).to be_one
    end

    it 'reports unknown method calls on constants' do
      checker = type_checker(%(
        String.not_a_method
      ))
      expect(checker.problems).to be_one
    end

    it 'validates inferred parameter types with complex tags' do
      checker = type_checker(%(
        # @param foo [Numeric, nil] a foo
        def test(foo: nil)
          foo
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'validates inferred return types with complex tags' do
      checker = type_checker(%(
        # @param foo [Numeric, nil] a foo
        # @return [Numeric, nil]
        def test(foo: nil)
          foo
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports inferred return types missing from complex tags' do
      checker = type_checker(%(
        # @return [Numeric, nil]
        def test
          'string'
        end
      ))
      expect(checker.problems).to be_one
      expect(checker.problems.first.message).to include('does not match inferred type')
    end

    it 'validates zsuper arity' do
      checker = type_checker(%(
        class Foo
          def meth(param_foo)
          end
        end

        class Bar < Foo
          def meth(param_bar)
            super
          end
        end
      ))
      expect(checker.problems).to be_empty
    end

    it 'reports unmatched zsuper arity' do
      checker = type_checker(%(
        class Foo
          def meth(param1, param2)
          end
        end

        class Bar < Foo
          def meth(param1)
            super
          end
        end
      ))
      expect(checker.problems).to be_one
    end

    it 'uses nil? to refine type' do
      pending 'nil? support in flow sensitive typing'

      checker = type_checker(%(
        # @sg-ignore
        # @type [String, nil]
        foo = bar()
        if foo.nil?
          foo.upcase
        else
          foo.downcase
        end
      ))
      expect(checker.problems.map(&:message)).to eq(['Unresolved call to upcase'])
    end

    it 'does not falsely enforce nil in return types' do
      checker = type_checker(%(
      # @return [Integer]
      def foo
        # @sg-ignore
        # @type [Integer, nil]
        a = bar
        a || 123
      end
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it 'refines types on is_a? and && to downcast and avoid false positives' do
      checker = type_checker(%(
        def foo
          # @sg-ignore
          # @type [Object]
          a = bar
          if a.is_a?(String) && a.length > 0
            a.upcase
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'interprets self references correctly' do
      checker = type_checker(%(
        class Bar
          # @param pin [self]
          # @return [void]
          def baz pin; end
        end

        class Foo
          # @return [Bar]
          attr_reader :bing

          # @param other [Foo]
          # @return [void]
          def try_merge!(other)
            bing.baz(other.bing)
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it "doesn't get confused about rooted types from attr_accessors" do
      checker = type_checker(%(
        module Foo
          class Symbol; end
          class Bar
            # @return [::Symbol]
            attr_accessor :bar
          end
       end
       class Quux
         def baz
           bar = Foo::Bar.new
           bar.bar = :foo
         end
       end
      ))
      expect(checker.problems).to be_empty
    end

    it "doesn't false alarm over splatted args which aren't the final argument" do
      checker = type_checker(%(
        # @param path [Array<String>]
        # @param baz [Array<String>]
        # @return [void]
        def foo *path, baz; end

        foo('a', 'b', 'c', ['d'])
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it "understands enough of define_method not to think the block is in class scope" do
      checker = type_checker(%(
        class Foo
          def initialize
            @resolved_method = nil
          end

          def bar
          end

          define_method('a') do
            bar
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'understands tuple superclass' do
      checker = type_checker(%(
        b = ['a', 'b', 123]
        c = b.include?('a')
        c
      ))
      expect(checker.problems.map(&:message)).to be_empty
    end

    it "Uses flow scope to specialize understanding of cvar types" do
      pending 'better cvar support'

      checker = type_checker(%(
        class Bar
          # @return [String]
          def foo
            'feh'
          end

          # @return [void]
          def reset_blah
            @blah = nil
          end
        end

        class Foo < Bar
          # @return [String]
          def foo
            @blah.upcase!
            if @blah.nil?
              @blah = super
              @blah.empty?
            end
            @blah
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq(["Unresolved call to upcase!"])
    end

    it "does not lose track of place and false alarm when using kwargs after a splat" do
      checker = type_checker(%(
        def foo(a, b, c); end
        def bar(*args, **kwargs, &blk)
          foo(*args, **kwargs, &blk)
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it "understands Array#+ overloads" do
      checker = type_checker(%(
        c = ['a'] + ['a']
        c
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it "understands String#+ overloads" do
      checker = type_checker(%(
        detail = ''
        detail += "foo"
        detail.strip!
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it "understands Enumerable#each via _Each self type" do
      checker = type_checker(%(
        class Blah
          # @param e [Enumerable<String>]
          # @return [void]
          def foo(e)
            e
            e.each do |x|
              x
            end
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not complain when passing nil to a NilClass parameter' do
      checker = type_checker(%(
        # @param a [NilClass]
        def foo(a); end

        foo(nil)
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not complain when passing NilClass to nil parameter' do
      checker = type_checker(%(
        # @param a [nil]
        def foo(a); end

        # @param a [NilClass]
        def bar(a)
          foo(a)
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not complain when passing true to TrueClass parameter' do
      checker = type_checker(%(
        # @param a [TrueClass]
        def foo(a); end

        foo(true)
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not complain when passing TrueClass to true parameter' do
      checker = type_checker(%(
        # @param a [true]
        def foo(a); end

        # @param a [TrueClass]
        def bar(a)
          foo(a)
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end

    it 'does not complain on defaulted reader with detailed expression' do
      checker = type_checker(%(
        class Foo
          # @return [Integer, nil]
          def bar
            @bar ||=
              if rand
                 123
               elsif rand
                 456
               end
          end
        end
      ))
      expect(checker.problems.map(&:message)).to eq([])
    end
  end
end
