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

  it "detects a recipient of an argument" do
    source = Solargraph::Source.load_string('abc.def(g)')
    fragment = source.fragment_at(0, 8)
    expect(fragment.argument?).to be(true)
    recipient = source.fragment_at(0, 0)
    expect(recipient.argument?).to be(false)
  end

  it "detects a recipient of multiple arguments" do
    source = Solargraph::Source.load_string('abc.def(g, h)')
    fragment = source.fragment_at(0, 11)
    expect(fragment.argument?).to be(true)
    recipient = source.fragment_at(0, 0)
    expect(recipient.argument?).to be(false)
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
    pins = fragment.complete(api_map).pins.map(&:path)
    expect(pins).to include('Kernel#puts')
  end

  it "returns signature chains" do
    source = Solargraph::Source.new('Foo::Bar.method_call.deeper')
    fragment = source.fragment_at(0, 10)
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

  it "detects comments in code with CRLF line endings" do
    source = Solargraph::Source.new("# comment line 0\r\n# comment line 1\r\nputs 'code'")
    fragment = source.fragment_at(1, 0)
    expect(fragment.comment?).to be(false)
    fragment = source.fragment_at(1, 1)
    expect(fragment.comment?).to be(true)
    fragment = source.fragment_at(2, 0)
    expect(fragment.comment?).to be(false)
  end

  it "returns empty strings for empty fragment components" do
    source = Solargraph::Source.new("a ")
    fragment = source.fragment_at(0, 3)
    expect(fragment.word).to be_empty
    expect(fragment.remainder).to be_empty
    expect(fragment.base).to be_empty
  end

  it "completes class methods" do
    source = Solargraph::Source.new(%(
      class Foo
        def self.bar
        end
      end
      Foo._
    ))
    api_map = Solargraph::ApiMap.new
    api_map.virtualize source
    fragment = source.fragment_at(5, 10)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:path)).to include('Foo.bar')
  end

  it "completes class methods for nested namespaces" do
    source = Solargraph::Source.new(%(
      class Foo
        class Bar
          def self.baz
          end
        end
      end
      Foo::Bar._
    ))
    api_map = Solargraph::ApiMap.new
    api_map.virtualize source
    fragment = source.fragment_at(7, 15)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:path)).to include('Foo::Bar.baz')
  end

  it "defines methods chained from literal strings" do
    api_map = Solargraph::ApiMap.new
    # Preceding code can affect detection of literals
    source = Solargraph::Source.load_string(%(
      puts 'hello'
      '123'.upcase.split
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 20)
    paths = fragment.define(api_map).map(&:path)
    expect(paths).to include('String#split')
  end

  it "excludes Kernel from literal string methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      '' 
    ))
    source.code.sub!("' ", "'.")
    api_map.virtualize source
    fragment = source.fragment_at(1, 9)
    cmp = fragment.complete(api_map)
    expect(cmp.pins).not_to be_empty
    expect(cmp.pins.select{|pin| pin.namespace == 'Kernel'}).to be_empty
  end

  it "infers global variable types" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      $foo = 'foo'
    ))
    api_map.virtualize source
    fragment = source.fragment_at(1, 7)
    pin = fragment.define(api_map).first
    expect(pin.return_type).to eq('String')
  end

  it "defines self instance methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foo
        def meth1
        end
        def meth2
          self.meth1
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(5, 16)
    pins = fragment.define(api_map)
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo#meth1')
  end

  it "defines self class methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foo
        def self.meth1
        end
        self.meth1
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(4, 14)
    pins = fragment.define(api_map)
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo.meth1')
  end

  it "infers local variable definitions with reassignments" do
    code = %(
      str = '1,2,3'
      str = str.split(',')
    )
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(code)
    api_map.virtualize source
    fragment = source.fragment_at(1, 7)
    pins = fragment.define(api_map)
    expect(pins.first.return_type).to eq('String')
    fragment = source.fragment_at(2, 7)
    fragment.locals
    pins = fragment.define(api_map)
    type = pins.first.infer(api_map)
    expect(type.tag).to eq('Array<String>')
  end

  it "infers instance variable definitions with reassignments" do
    code = %(
      @str = '1,2,3'
      @str = @str.split(',')
    )
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(code)
    api_map.virtualize source
    fragment = source.fragment_at(1, 7)
    pins = fragment.define(api_map)
    expect(pins.first.return_type).to eq('String')
    fragment = source.fragment_at(2, 7)
    # @todo There might not be a good way to handle instance variable pins
    #   with conflicting types, but at the very least, assignments that
    #   reference themselves should not raise a SystemStackError.
    expect {
      pins = fragment.define(api_map)
    }.not_to raise_error
  end

  it "suggests nested namespaces" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      module Foo
        class Bar
        end
      end
      Foo::_
    ), 'file.rb')
    api_map.virtualize source
    fragment = source.fragment_at(5, 11)
    result = fragment.complete(api_map).pins.map(&:name)
    expect(result.length).to eq(1)
    expect(result).to include('Bar')
    fragment = source.fragment_at(5, 11)
    result = fragment.complete(api_map).pins.map(&:name)
    expect(result.length).to eq(1)
    expect(result).to include('Bar')
  end

  it "suggests completions in string interpolation" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string('
      world = \'world\'
      greeting = "hello #{}"
    ', 'file.rb')
    api_map.virtualize source
    fragment = source.fragment_at(2, 26)
    expect(fragment.string?).to be(false)
    expect(fragment.comment?).to be(false)
    items = fragment.complete(api_map).pins.map(&:name)
    expect(items).to include('world')
  end

  it "finds private methods in the same scope and context" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string('
      class Foobar
        def bazbar
          s
        end

        private

        def shazbot
        end
      end
    ', 'file.rb')
    api_map.virtualize source
    fragment = source.fragment_at(3, 10)
    items = fragment.complete(api_map).pins.map(&:path)
    expect(items).to include('Foobar#shazbot')
  end

  it "selects non-nil local variable assignments" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string('
      a = nil
      a = []
      a._
    ')
    api_map.virtualize source
    fragment = source.fragment_at(3, 8)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:path)).to include('Array#each')
  end

  it "returns core namespaces from namespace contexts" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      class Foo
        S
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 9)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('String')
  end

  it "completes literal strings" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("'string'._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 9)
    paths = fragment.complete(api_map).pins.map(&:path)
    expect(paths).to include('String#upcase')
  end

  it "completes literal arrays" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("[]._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 3)
    paths = fragment.complete(api_map).pins.map(&:path)
    expect(paths).to include('Array#length')
  end

  it "completes literal hashes" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("{}._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 3)
    paths = fragment.complete(api_map).pins.map(&:path)
    expect(paths).to include('Hash#has_key?')
  end

  it "completes literal integers" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("1._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 2)
    paths = fragment.complete(api_map).pins.map(&:name)
    expect(paths).to include('abs')
  end

  it "completes method chains from literal strings" do
    api_map = Solargraph::ApiMap.new
    # Preceding code can affect detection of literals
    source = Solargraph::Source.load_string(%(
      puts 'hello'
      '123'.upcase._
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 19)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('split')
  end

  it "adds local variables to completion items" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("lvar = 'foo'\nl")
    api_map.virtualize source
    fragment = source.fragment_at(1, 1)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('lvar')
  end

  it "completes global variables" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      $foo = 'foo'
      $f
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 8)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('$foo')
  end

  it "includes methods from domain directives in sources" do
    api_map = Solargraph::ApiMap.new
    # @todo Comments with directives need to be associated with a node in order
    #   to get processed. There may not be a simple way to get around that
    #   requirement.
    source = Solargraph::Source.new(%(
      # @!domain String
      x
    ))
    expect(source.domains).to include('String')
    api_map.virtualize source
    fragment = source.fragment_at(2, 0)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('upcase')
  end

  it "includes private module instance methods in class namespaces" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foo
      end
      ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 0)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('private')
  end

  it "includes private module instance methods in module namespaces" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
      end
      ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 0)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('private')
    expect(names).to include('module_function')
  end

  it "excludes private module instance methods from the global namespace" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      x
      ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 0)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).not_to include('private')
    expect(names).not_to include('module_function')
  end

  it "filters completion results based on the current word" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      re
      ))
    api_map.virtualize source
    fragment = source.fragment_at(1, 8)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('rescue')
    expect(names).not_to include('raise')
    fragment = source.fragment_at(1, 7)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('rescue')
    expect(names).to include('raise')
  end

  it "infers local variable types derived from other local variables" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      x = '123'
      y = x.split
      y._
      ))
    api_map.virtualize source
    fragment = source.fragment_at(3, 8)
    names = fragment.complete(api_map).pins.map(&:name)
    expect(names).to include('join')
  end

  it "detects class variables" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
        @@foo = 'foo'
        def bar
          @@foo
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(4, 12)
    pins = fragment.complete(api_map).pins
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@@foo')
    expect(pins.first.return_type).to eq('String')
  end

  it "includes duck type methods in completion results" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foobar
        # @param sound [#vocalize]
        def quack sound
          sound._
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(4, 16)
    cmp = fragment.complete(api_map)
    names = cmp.pins.map(&:name)
    expect(names).to include('vocalize')
  end

  it "detects multiple duck type methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      class Foobar
        # @param sound [#vocalize, #emit]
        def quack sound
          sound._
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(4, 16)
    cmp = fragment.complete(api_map)
    names = cmp.pins.map(&:name)
    expect(names).to include('vocalize')
    expect(names).to include('emit')
  end

  it "detects completion items for instance variables" do
    code = %(
      @thing = String.new
      @thing._
    )
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(code)
    api_map.virtualize source
    fragment = source.fragment_at(2, 13)
    cmp = fragment.complete(api_map)
    names = cmp.pins.map(&:name)
    expect(names).to include('upcase')
  end

  it "detects completion items for class variables" do
    code = %(
      @@thing = String.new
      @@thing._
    )
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(code)
    api_map.virtualize source
    fragment = source.fragment_at(2, 14)
    cmp = fragment.complete(api_map)
    names = cmp.pins.map(&:name)
    expect(names).to include('upcase')
  end

  it "signifies methods chained from literal arrays" do
    api_map = Solargraph::ApiMap.new
    # Preceding code can affect detection of literals
    source = Solargraph::Source.load_string(%(
      puts 'hello'
      %w[1 2 3].join.split()
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 27)
    paths = fragment.signify(api_map).map(&:path)
    expect(paths).to include('String#split')
  end

  it "filters for methods in signify" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      x = 'string'
      x()
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 8)
    pins = fragment.signify(api_map)
    expect(pins).to be_empty
  end


  it "scopes mixin methods" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Mixin
        def mixin_method; end
      end
      class Container
        include Mixin
        m
        def bar
          m
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(6, 9)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:name)).not_to include('mixin_method')
    fragment = source.fragment_at(8, 11)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:name)).to include('mixin_method')
  end

  it "keeps mixins from parents out of scope" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Mixin
        def mixin_method
        end
      end
      class Container
        include Mixin
        def bar
        end
        class Child
          m
        end
      end
    ))
    api_map.virtualize source
    fragment = source.fragment_at(10, 11)
    cmp = fragment.complete(api_map)
    expect(cmp.pins.map(&:name)).not_to include('mixin_method')
  end
end
