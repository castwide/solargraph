describe Solargraph::Source::Fragment do
  it "detects an instance variable from a fragment" do
    source = Solargraph::Source.load_string('@foo')
    fragment = source.fragment_at(0, 1)
    expect(fragment.word).to eq('@')
  end

  it "detects a whole instance variable from a fragment" do
    source = Solargraph::Source.load_string('@foo')
    fragment = source.fragment_at(0, 1)
    expect(fragment.whole_word).to eq('@foo')
  end

  it "detects a class variable from a fragment" do
    source = Solargraph::Source.load_string('@@foo')
    fragment = source.fragment_at(0, 2)
    expect(fragment.word).to eq('@@')
  end

  it "detects a whole class variable from a fragment" do
    source = Solargraph::Source.load_string('@@foo')
    fragment = source.fragment_at(0, 2)
    expect(fragment.whole_word).to eq('@@foo')
  end

  it "detects a namespace" do
    source = Solargraph::Source.load_string(%(
      class Foo

      end
    ))
    fragment = source.fragment_at(2, 0)
    expect(fragment.namespace).to eq('Foo')
  end

  it "detects a nested namespace" do
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar

        end
      end
    ))
    fragment = source.fragment_at(3, 0)
    expect(fragment.namespace).to eq('Foo::Bar')
  end

  it "detects a local variable in the global namespace" do
    source = Solargraph::Source.load_string(%(
      foo = bar
    ))
    fragment = source.fragment_at(2, 0)
    expect(fragment.locals.length).to eq(1)
    expect(fragment.locals.first.name).to eq('foo')
  end

  it "detects a string" do
    source = Solargraph::Source.load_string(%(
      "foo"
    ))
    fragment = source.fragment_at(1, 7)
    expect(fragment.string?).to be(true)
  end

  it "detects an interpolation in a string" do
    source = Solargraph::Source.load_string('
      "#{}"
    ')
    fragment = source.fragment_at(1, 9)
    expect(fragment.string?).to be(false)
  end

  it "detects an interpolation in a mixed string" do
    source = Solargraph::Source.load_string('
      "hello #{}"
    ')
    fragment = source.fragment_at(1, 15)
    expect(fragment.string?).to be(false)
  end

  it "ignores parens and brackets in signatures" do
    source = Solargraph::Source.load_string('
      foo(1).bar{|x|y}.baz()
    ')
    fragment = source.fragment_at(1, 24)
    expect(fragment.signature).to eq('foo.bar.b')
    expect(fragment.whole_signature).to eq('foo.bar.baz')
    expect(fragment.base).to eq('foo.bar')
    expect(fragment.word).to eq('b')
    expect(fragment.whole_word).to eq('baz')
  end

  it "detects a recipient of an argument" do
    source = Solargraph::Source.load_string('abc.def(g)')
    fragment = source.fragment_at(0, 8)
    # expect(fragment.argument?).to be(true)
    expect(fragment.recipient.whole_signature).to eq('abc.def')
  end

  it "detects a recipient of multiple arguments" do
    source = Solargraph::Source.load_string('abc.def(g, h)')
    fragment = source.fragment_at(0, 11)
    # expect(fragment.argument?).to be(true)
    expect(fragment.recipient.whole_signature).to eq('abc.def')
  end

  it "knows positions in strings" do
    source = Solargraph::Source.load_string("x = '123'")
    fragment = source.fragment_at(0, 1)
    expect(fragment.string?).to be(false)
    fragment = source.fragment_at(0, 5)
    expect(fragment.string?).to be(true)
  end

  it "knows positions in comments" do
    source = Solargraph::Source.load_string("# comment\nx = '123'")
    fragment = source.fragment_at(0, 1)
    expect(fragment.comment?).to be(true)
    fragment = source.fragment_at(1, 0)
    expect(fragment.string?).to be(false)
  end

  it "infers methods from blanks" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(3, 0)
    pins = api_map.complete(fragment).pins.map(&:path)
    expect(pins).to include('Kernel#puts')
  end

  it "returns signature roots" do
    source = Solargraph::Source.new('Foo::Bar.method_call')
    fragment = source.fragment_at(0, 10)
    expect(fragment.root).to eq('Foo::Bar')
  end

  it "returns signature chains" do
    source = Solargraph::Source.new('Foo::Bar.method_call.deeper')
    fragment = source.fragment_at(0, 10)
    expect(fragment.chain).to eq('m')
    expect(fragment.base_chain).to eq('')
    expect(fragment.whole_chain).to eq('method_call')
  end

  it "handles signatures ending with ." do
    source = Solargraph::Source.new('Foo::Bar.method_call.')
    fragment = source.fragment_at(0, 21)
    expect(fragment.signature).to eq('Foo::Bar.method_call.')
    expect(fragment.base).to eq('Foo::Bar.method_call')
  end

  it "includes local variables from a block's named context" do
    source = Solargraph::Source.new(%(
      lvar = 'lvar'
      100.times do
        puts
      end
    ))
    fragment = source.fragment_at(3, 0)
    expect(fragment.locals.length).to eq(1)
    expect(fragment.locals[0].name).to eq('lvar')
  end

  it "excludes local variables from different blocks" do
    source = Solargraph::Source.new(%(
      100.times do
        lvar = 'lvar'
      end
      100.times do

      end
    ))
    fragment = source.fragment_at(5, 0)
    expect(fragment.locals).to be_empty
  end

  # @todo Fragment is no longer responsible for calculating locals.
  # it "calculates local variables with literal assignments" do
  #   source = Solargraph::Source.new(%(
  #     abc = '123'
  #     abc._
  #   ))
  #   fragment = source.fragment_at(2, 10)
  #   expect(fragment.signature).to eq('abc.')
  #   expect(fragment.calculated_signature).to eq('String.new.')
  # end

  # it "calculates local variables that reference each other" do
  #   source = Solargraph::Source.new(%(
  #     str1 = '123'
  #     str2 = str1
  #     str2._
  #   ))
  #   fragment = source.fragment_at(3, 11)
  #   expect(fragment.signature).to eq('str2.')
  #   expect(fragment.calculated_signature).to eq('String.new.')
  # end

  # it "returns assignments in calculated signatures" do
  #   source = Solargraph::Source.new(%(
  #     foo = Foo.new
  #     bar = foo
  #     bar._
  #   ))
  #   fragment = source.fragment_at(2, 15)
  #   expect(fragment.signature).to eq('foo')
  #   expect(fragment.calculated_signature).to eq('Foo.new')
  #   fragment = source.fragment_at(3, 10)
  #   expect(fragment.signature).to eq('bar.')
  #   expect(fragment.calculated_signature).to eq('Foo.new.')
  # end

  # @todo This might not be the responsibility of the fragment.
  # it "calculates unrecognized namespaces" do
  #   source = Solargraph::Source.new(%(
  #     Foo.new
  #   ))
  #   fragment = source.fragment_at(1, 13)
  #   expect(fragment.signature).to eq('Foo.new')
  #   expect(fragment.calculated_signature).to eq('Foo.new')
  # end

  # @todo This might not be the responsibility of the fragment.
  # it "calculates nested namespaces" do
  #   source = Solargraph::Source.new(%(
  #     class Foo
  #       class Bar
  #         def self.make
  #           Bar.new
  #         end
  #       end
  #     end
  #   ))
  #   fragment = source.fragment_at(4, 19)
  #   expect(fragment.signature).to eq('Bar.new')
  #   expect(fragment.calculated_signature).to eq('Foo::Bar.new')
  # end
end
