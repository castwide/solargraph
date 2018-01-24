require 'tmpdir'

describe Solargraph::CodeMap do
  before :all do
    @workspace = Dir.mktmpdir
    @filename = "#{@workspace}/test.rb"
  end

  after :all do
    FileUtils.remove_entry @workspace
  end

  it "identifies position in def node" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        def bar
          @bar = ''
        end
        def baz
          @
        end
      end
    ))
    node = code_map.node_at(92)
    expect(node.type).to eq(:def)
  end

  it "converts lines and columns to offsets" do
    code_map = Solargraph::CodeMap.new(code: "class Foo\n  def foo;end\nend")
    offset = code_map.get_offset(1, 9)
    expect(offset).to eq(19)
  end

  it "converts lines and columns to offsets with carriage returns" do
    code_map = Solargraph::CodeMap.new(code: "class Foo\r\n  def foo;end\r\nend")
    offset = code_map.get_offset(1, 9)
    expect(offset).to eq(19)
  end

  it "detects instance variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        def bar
          @bar = ''
        end
        def baz
          @
        end
      end
    ))
    result = code_map.suggest_at(92)
    expect(result.map(&:to_s)).to include('@bar')
  end

  it "identifies position in class node" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        @cvar = ''
        def bar
          @bar = ''
        end
        @
      end
    ))
    node = code_map.node_at(93)
    expect(node.type).to eq(:class)
  end

  it "detects class instance variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        @cvar = ''
        def bar
          @bar = ''
        end
        @
      end
    ))
    result = code_map.suggest_at(93)
    expect(result.map(&:to_s)).to include('@cvar')
    expect(result.map(&:to_s)).not_to include('@bar')
  end

  it "detects class variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        @@var = ''
        @@var.a
      end
    ))
    result = code_map.suggest_at(48)
    expect(result.map(&:to_s)).to include('@@var')
  end

  it "detects local variables and instance methods" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        def bar
          @bar = ''
        end
        def baz
          boo = ''
          b
        end
      end
    ))
    result = code_map.suggest_at(111)
    expect(result.map(&:to_s)).to include('bar')
    expect(result.map(&:to_s)).to include('baz')
    expect(result.map(&:to_s)).to include('boo')
  end

  it "gets instance methods for literals" do
    code_map = Solargraph::CodeMap.new(code: "'string'.")
    result = code_map.suggest_at(9)
    expect(result.map(&:to_s)).to include('upcase')
  end

  it "resolves signatures to documentation" do
    code_map = Solargraph::CodeMap.new(code: "x = [];x.join")
    suggestions = code_map.resolve_object_at(12)
    expect(suggestions.length).to eq(1)
    expect(suggestions[0].path).to eq('Array#join')
  end

  it "detects variable types from @type tags" do
    code_map = Solargraph::CodeMap.new(code: %(
      # @type [String]
      my_var = some_method_call
      my_var.
    ))
    sugg = code_map.suggest_at(69)
    expect(sugg.map{ |s| s.label }).to include('upcase')
    sugg = code_map.resolve_object_at(67)
    expect(sugg[0].path).to eq('String')
  end

  it "infers the type of an instance variable" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        @cvar = ''
        def bar
          @bar = ''
        end
        @
      end
    ))
    sugg = code_map.resolve_object_at(63)
    expect(sugg.length).to eq(1)
    expect(sugg[0].path).to eq('String')
  end

  it "detects a nested class name" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        class Bar
        end
      end
      Foo::Bar.
    ))
    sugg = code_map.suggest_at(69)
    expect(sugg.map(&:to_s)).to include('Bar')
  end

  it "detects a nested class method" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        class Bar
        end
      end
      Foo::Bar.
    ))
    sugg = code_map.suggest_at(72)
    expect(sugg.map(&:to_s)).to include('new')
  end

  it "detects a class instance from a new method" do
    code_map = Solargraph::CodeMap.new(code: 'String.new.')
    sugg = code_map.suggest_at(11)
    expect(sugg.map(&:to_s)).to include('upcase')
  end

  it "infers signatures from method arguments" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @param baz [String]
        def bar baz
          baz.split(',').
        end
      end
    ), cursor: [4, 25])
    sig = code_map.infer_signature_at(code_map.get_offset(4, 13))
    expect(sig).to eq('String')
    sig = code_map.infer_signature_at(code_map.get_offset(4, 25))
    expect(sig).to eq('Array')
  end

  it "infers signatures from yield params" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldparam baz [Array]
        def bar;end
      end
      foo = Foo.new
      foo.bar do |par|
        par
      end
    ))
    offset = code_map.get_offset(7, 11)
    sig = code_map.infer_signature_at(offset)
    expect(sig).to eq('Array')
  end

  it "infers local method call types from return tags" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @return [Array]
        def bar
        end
        def baz
          bar.
        end
      end
    ), cursor: [6, 14])
    offset = code_map.get_offset(6, 14)
    sig = code_map.infer_signature_at(offset)
    expect(sig).to eq('Array')
  end

  it "infers chained method call types" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Thing1
        # @return [Array]
        def foo bar, baz
        end
      end
      class Thing2
        # @return [Thing1]
        def get_thing1
        end
        def baz
          get_thing1.foo(number, 'string').
        end
      end
    ), cursor: [11, 43])
    offset = code_map.get_offset(11, 43)
    sig = code_map.infer_signature_at(offset)
    expect(sig).to eq('Array')
  end

  it "detects signature types for instance variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo;end
      @foo = Foo.new
      @foo.
    ))
    offset = code_map.get_offset(3, 11)
    sig = code_map.infer_signature_at(offset)
    expect(sig).to eq('Foo')
  end

  it "detects signature types for class variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo;end
      @@foo = Foo.new
      @@foo.
    ))
    offset = code_map.get_offset(3, 12)
    sig = code_map.infer_signature_at(offset)
    expect(sig).to eq('Foo')
  end

  it "infers types from literal values with chained methods" do
    code_map = Solargraph::CodeMap.new(code: "%w[one two].join(',').to_i.")
    type = code_map.infer_signature_at(27)
    expect(type).to eq('Integer')
    code_map = Solargraph::CodeMap.new(code: "[].join(',').length.")
    type = code_map.infer_signature_at(20)
    expect(type).to eq('Integer')
  end

  it "infers signatures for literal integers" do
    ["0", "123"].each do |num|
      code_map = Solargraph::CodeMap.new(code: "#{num}.")
      type = code_map.infer_signature_at(num.length + 1)
      expect(type).to eq('Integer')
    end
  end

  it "infers signatures for methods of literal integers" do
    code_map = Solargraph::CodeMap.new(code: "123.to_s.")
    type = code_map.infer_signature_at(9)
    expect(type).to eq('String')
  end

  it "finds suggestions for literal integers with methods" do
    code_map = Solargraph::CodeMap.new(code: "123.to_s.")
    sugg = code_map.suggest_at(9)
    expect(sugg.map(&:to_s)).to include('upcase')
  end

  it "infers signatures for literal floats" do
    code_map = Solargraph::CodeMap.new(code: "3.14.")
    type = code_map.infer_signature_at(5)
    expect(type).to eq('Float')
  end

  it "infers signatures for methods of literal floats" do
    code_map = Solargraph::CodeMap.new(code: "3.14.to_s.")
    type = code_map.infer_signature_at(10)
    expect(type).to eq('String')
  end

  it "infers signatures for multi-line % strings" do
    code_map = Solargraph::CodeMap.new(code: %(
      %(
        string
      ).
    ))
    type = code_map.infer_signature_at(33)
    expect(type).to eq('String')
  end

  it "infers types from literal strings with chained methods" do
    code_map = Solargraph::CodeMap.new(code: "''.split(',').length.")
    type = code_map.infer_signature_at(21)
    expect(type).to eq('Integer')
  end

  it "ignores special characters in strings" do
    code_map = Solargraph::CodeMap.new(code: "''.split('[').")
    type = code_map.infer_signature_at(14)
    expect(type).to eq('Array')
    code_map = Solargraph::CodeMap.new(code: %[
      %[
        ()(
      ].
    ])
    type = code_map.infer_signature_at(30)
    expect(type).to eq('String')
  end

  it "infers types for literal arrays" do
    code_map = Solargraph::CodeMap.new(code: '[].')
    type = code_map.infer_signature_at(3)
    expect(type).to eq('Array')
  end

  it "returns suggestions for literal arrays" do
    code_map = Solargraph::CodeMap.new(code: '[].')
    sugg = code_map.suggest_at(3)
    expect(sugg.map(&:to_s)).to include('join')
  end

  it "infers literal symbols" do
    code_map = Solargraph::CodeMap.new(code: ':foo.')
    type = code_map.infer_signature_at(5)
    expect(type).to eq('Symbol')
  end

  it "infers literal strings" do
    code_map = Solargraph::CodeMap.new(code: %(
      'string'.
    ))
    type = code_map.infer_signature_at(code_map.get_offset(1, 15))
    expect(type).to eq('String')
  end

  it "infers constants" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        BAR = 'bar'
      end
      Foo::BAR.
    ))
    type = code_map.infer_signature_at(62)
    expect(type).to eq('String')
    sugg = code_map.suggest_at(62)
    expect(sugg.map(&:to_s)).to include('upcase')
  end

  it "returns empty suggestions for unrecognized signature types" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @return [UnknownClass]
        def bar
        end
      end
      foo = Foo.new
      foo.bar.
    ))
    sugg = code_map.suggest_at(code_map.get_offset(7, 14))
    expect(sugg.length).to eq(0)
  end

  it "returns empty suggestions for undefined signature types" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        def bar
        end
      end
      foo = Foo.new
      foo.bar.
    ))
    sugg = code_map.suggest_at(89)
    expect(sugg.length).to eq(0)
  end

  it "infers a method's return type from a tag" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @return [Hash]
        def bar
        end
      end
      foo = Foo.new
      foo.bar
    ))
    sugg = code_map.resolve_object_at(code_map.get_offset(7, 12))
    expect(sugg[0].return_type).to eq('Hash')
  end

  it "infer's a method's suggestion from its path" do
    code_map = Solargraph::CodeMap.new(code: %(
      my_hash = {}
      my_hash.length
    ))
    sugg = code_map.resolve_object_at(code_map.get_offset(2, 18))
    expect(sugg[0].label).to eq('length')
  end

  it "infers a local class" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo;end
      Foo
    ))
    sugg = code_map.resolve_object_at(code_map.get_offset(2, 8))
    expect(sugg[0].label).to eq('Foo')
  end

  it "suggests symbols" do
    code_map = Solargraph::CodeMap.new(code: %(
      [:foo, :bar]
      :f
    ))
    sugg = code_map.suggest_at(code_map.get_offset(2, 8)).map(&:to_s)
    expect(sugg).to include(':foo')
    expect(sugg).to include(':bar')
  end

  it "finds local variables in scope" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        def bar
          lvar = 'lvar'
          lvar
        end
        def baz
          lvar
        end
      end
      lvar
    ))
    sugg = code_map.suggest_at(code_map.get_offset(4, 13)).map(&:to_s)
    expect(sugg).to include('lvar')
    sugg = code_map.suggest_at(code_map.get_offset(7, 13)).map(&:to_s)
    expect(sugg).not_to include('lvar')
    sugg = code_map.suggest_at(code_map.get_offset(10, 9)).map(&:to_s)
    expect(sugg).not_to include('lvar')
  end

  it "returns global variable suggestions" do
    code_map = Solargraph::CodeMap.new(code: %(
      $foo = 'foo'
      # @type [Array]
      $bar = 'bar'
      $
    ), cursor: [4, 7])
    sugg = code_map.suggest_at(code_map.get_offset(4, 7)).map(&:to_s)
    expect(sugg).to include('$foo')
    expect(sugg).to include('$bar')
  end

  it "infers global variable types" do
    code = %(
      $foo = 'foo'
      $foo.
    )
    code_map = Solargraph::CodeMap.new(code: code, cursor: [2, 11])
    type = code_map.infer_signature_at(code_map.get_offset(2, 11))
    expect(type).to eq('String')
  end

  it "ignores unknown local methods/variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      foo.
    ), cursor: [1, 10])
    sugg = code_map.suggest_at(code_map.get_offset(1, 10))
    expect(sugg.length).to eq(0)
  end

  it "returns unique local variables" do
    code_map = Solargraph::CodeMap.new(code: %(
      foo = 1
      foo = 'foo'
    ), cursor: [0, 0])
    sugg = code_map.suggest_at(code_map.get_offset(0, 0)).select{|s| s.label == 'foo'}
    expect(sugg.length).to eq(1)
  end

  it "prefers local variables with non-nil assignments" do
    code_map = Solargraph::CodeMap.new(code: %(
      foo = nil
      foo = 'foo'
    ), cursor: [0, 0])
    sugg = code_map.suggest_at(code_map.get_offset(0, 0)).select{|s| s.label == 'foo'}
    expect(sugg.length).to eq(1)
    expect(sugg[0].return_type).to eq('String')
  end

  it "accepts local variables with nil assignments and return types" do
    code_map = Solargraph::CodeMap.new(code: %(
      # @type [Array]
      foo = nil
      foo = 'foo'
    ), cursor: [0, 0])
    sugg = code_map.suggest_at(code_map.get_offset(0, 0)).select{|s| s.label == 'foo'}
    expect(sugg.length).to eq(1)
    expect(sugg[0].return_type).to eq('Array')
  end

  it "infers types for local variables in nil guards" do
    code_map = Solargraph::CodeMap.new(code: %(
      x ||= 'string'
      x.
    ))
    type = code_map.infer_signature_at(code_map.get_offset(2, 8))
    expect(type).to eq('String')
  end

  it "infers types and gets Module instance methods for modules" do
    # Use Foo2 instead of Foo because a Foo class apparently exists
    code_map = Solargraph::CodeMap.new(code: %(
      module Foo2
      end
      Foo2.
    ))
    type = code_map.infer_signature_at(code_map.get_offset(3, 11))
    expect(type).to eq('Module<Foo2>')
    sugg = code_map.suggest_at(code_map.get_offset(3, 11)).map(&:to_s)
    expect(sugg).to include('module_exec')
    expect(sugg).not_to include('allocate')
  end

  it "infers types of yield params for instance method blocks" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldparam [String]
        def bar
        end
      end
      Foo.new.bar do |baz|
        baz._
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(7, 12))
    expect(type).to eq('String')
  end

  it "infers types of yield params for class method blocks" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldparam [String]
        def self.bar
        end
      end
      Foo.bar do |baz|
        baz._
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(7, 12))
    expect(type).to eq('String')
  end

  it "infers types of yield params for internal blocks" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldparam [String]
        def self.bar
        end
        bar do |baz|
          baz._
        end
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(6, 14))
    expect(type).to eq('String')
  end

  it "infers types of yield params for superclasses" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldparam [String]
        def self.bar
        end
      end
      class Foo2 < Foo
        bar do |baz|
          baz._
        end
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(8, 14))
    expect(type).to eq('String')
  end

  it "uses type tags for local variables inside blocks" do
    code_map = Solargraph::CodeMap.new(code: %(
      1.times do
        # @type [Array]
        foo = 'foo'
        foo._
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(4, 12))
    expect(type).to eq('Array')
    sugg = code_map.suggest_at(code_map.get_offset(4, 12)).map(&:to_s)
    expect(sugg).to include('each') # Array method
    expect(sugg).not_to include('downcase') # String method
  end

  it "infers types from subtypes for yielded params" do
    code_map = Solargraph::CodeMap.new(code: %(
      # @type [Array<String>]
      x = ['foo']
      x.each do |y|
        y._
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(4, 10))
    expect(type).to eq('String')
  end

  it "detects block context from yieldself tags" do
    code_map = Solargraph::CodeMap.new(code: %(
      module Foo
        # @yieldself [String]
        def self.bar
        end
      end
      Foo.bar do
        u
      end
    ))
    sugg = code_map.suggest_at(code_map.get_offset(7, 9)).map(&:to_s)
    expect(sugg).to include('upcase')
  end

  it "handles whitespace in signatures" do
    code_map = Solargraph::CodeMap.new(code: %(
      x = String.
        new
        .split
      x._
    ))
    type = code_map.infer_signature_at(code_map.get_offset(4, 8))
    expect(type).to eq('Array')
  end

  it "resolves self in yieldself tags" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @yieldself [self]
        def bar
        end
      end
      Foo.new.bar do
        b
      end
    ))
    sugg = code_map.suggest_at(code_map.get_offset(7, 9)).map(&:to_s)
    expect(sugg).to include('bar')
  end

  it "infers yielded param types from methods yielding subtypes" do
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
        # @param things [Array<String>]
        def bar things
          things.each do |str|
            str
          end
        end
      end
    ))
    type = code_map.infer_signature_at(code_map.get_offset(5, 15))
    expect(type).to eq('String')
  end

  it "infers from subtypes for Array#[] calls" do
    code_map = Solargraph::CodeMap.new(code: %(
      # @type [Array<String>]
      arr = [x]
      arr[0]
    ))
    type = code_map.infer_signature_at(code_map.get_offset(3, 12))
    expect(type).to eq('String')
  end

  it "returns empty suggestions for bare periods" do
    code_map = Solargraph::CodeMap.new(code: %(
      .
    ))
    sugg = code_map.suggest_at(code_map.get_offset(1, 7))
    expect(sugg.length).to eq(0)
    sugg = code_map.suggest_at(code_map.get_offset(1, 8))
    expect(sugg.length).to eq(0)
    code_map = Solargraph::CodeMap.new(code: %(
      class Foo
      end
      .
    ))
    sugg = code_map.suggest_at(code_map.get_offset(3, 7))
    expect(sugg.length).to eq(0)
  end
end
