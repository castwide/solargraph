require 'tmpdir'

describe Solargraph::ApiMap do
  before :each do
    code = %(
      module Module1
        class Module1Class
          class Module1Class2
          end
          def module1class_method
          end
        end
        def module1_method
        end
      end
      class Class1
        include Module1
        attr_accessor :access_foo
        attr_reader :read_foo
        attr_writer :write_foo
        def bar
          @bar ||= 'bar'
        end
        def self.baz
          @baz = 'baz'
        end
        def bing
          if x == y
            @bing = z
          end
        end
      end
      class Class2 < Class1
      end
    )
    @api_map = Solargraph::ApiMap.new
    @api_map.virtualize_string(code, 'file.rb')
  end

  it "finds instance methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('bar')
    expect(methods.map(&:to_s)).not_to include('baz')
  end

  it "finds included instance methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:name)).to include('module1_method')
  end

  it "finds superclass instance methods" do
    methods = @api_map.get_methods("Class2")
    expect(methods.map(&:to_s)).to include('bar')
    expect(methods.map(&:to_s)).to include('module1_method')
  end

  it "finds singleton methods" do
    methods = @api_map.get_methods("Class1", scope: :class)
    expect(methods.map(&:to_s)).to include('baz')
    expect(methods.map(&:to_s)).not_to include('bar')
  end

  it "finds instance variables" do
    vars = @api_map.get_instance_variable_pins("Class1")
    expect(vars.map(&:to_s)).to include('@bar')
    expect(vars.map(&:to_s)).not_to include('@baz')
  end

  it "finds instance variables inside blocks" do
    vars = @api_map.get_instance_variable_pins("Class1")
    expect(vars.map(&:to_s)).to include('@bing')
  end

  it "finds root instance variables" do
    code = %(
      class Foo
        @not1 = ''
        def bar
          @not2 = ''
        end
      end
      @foobar = ''
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    vars = api_map.get_instance_variable_pins('', :class).map(&:to_s)
    expect(vars).to include('@foobar')
    expect(vars).not_to include('@not1')
    expect(vars).not_to include('@not2')
  end

  it "finds class instance variables" do
    vars = @api_map.get_instance_variable_pins("Class1", :class)
    expect(vars.map(&:to_s)).to include('@baz')
    expect(vars.map(&:to_s)).not_to include('@bar')
  end

  it "finds attr_read methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('read_foo')
    expect(methods.map(&:to_s)).not_to include('read_foo=')
  end

  it "finds attr_write methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('write_foo=')
    expect(methods.map(&:to_s)).not_to include('write_foo')
  end

  it "finds attr_accessor methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('access_foo')
    expect(methods.map(&:to_s)).to include('access_foo=')
  end

  it "finds root namespaces" do
    namespaces = @api_map.get_constants('')
    expect(namespaces.map(&:to_s)).to include("Class1")
  end

  it "finds included namespaces" do
    namespaces = @api_map.get_constants('Class1')
    expect(namespaces.map(&:to_s)).to include('Module1Class')
  end

  it "finds namespaces within namespaces" do
    namespaces = @api_map.get_constants('Module1')
    expect(namespaces.map(&:to_s)).to include('Module1Class')
  end

  it "excludes namespaces outside of scope" do
    namespaces = @api_map.get_constants('')
    expect(namespaces.map(&:to_s)).not_to include('Module1Class')
  end

  # @todo Deprecating get_type_methods
  # it "finds instance variables in scoped classes" do
  #   # methods = @api_map.get_instance_methods('Module1Class', 'Module1')
  #   methods = @api_map.get_type_methods('Module1Class', 'Module1')
  #   expect(methods.map(&:to_s)).to include('module1class_method')
  # end

  it "finds namespaces beneath the current scope" do
    expect(@api_map.namespace_exists?('Class1', 'Module1')).to be true
  end

  it "finds fully qualified namespaces" do
    expect(@api_map.namespace_exists?('Module1::Module1Class')).to be true
  end

  it "finds partially qualified namespaces in specified scopes" do
    expect(@api_map.namespace_exists?('Module1Class::Module1Class2', 'Module1')).to be true
    expect(@api_map.namespace_exists?('Module1Class::Module1Class2', 'Class1')).to be false
  end

  # it "infers instance variable classes" do
  #   cls = @api_map.infer_instance_variable('@bar', 'Class1', :instance)
  #   expect(cls).to eq('String')
  # end

  it "checks visibility of instance methods" do
    code = %(
      class Foo
        def bar;end
        private
        def baz;end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    suggestions = api_map.get_methods('Foo', visibility: [:public])
    expect(suggestions.map(&:to_s)).to include('bar')
    expect(suggestions.map(&:to_s)).not_to include('baz')
    suggestions = api_map.get_methods('Foo', visibility: [:private])
    expect(suggestions.map(&:to_s)).not_to include('bar')
    expect(suggestions.map(&:to_s)).to include('baz')
  end

  it "finds singleton methods in class << self blocks" do
    code = %(
      class Foo
        class << self
          def bar
          end
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    sugg = api_map.get_methods('Foo', scope: :class)
    expect(sugg.map(&:to_s)).to include('bar')
  end

  it "gets method arguments" do
    code = %(
      class Foo
        def bar baz, boo = 'boo'
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    sugg = api_map.get_methods('Foo').keep_if{|s| s.name == 'bar'}.first
    expect(sugg.parameters).to eq(['baz', "boo = 'boo'"])
  end

  it "gets method keyword arguments" do
    code = %(
      class Foo
        def bar baz:, boo: 'boo'
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    sugg = api_map.get_methods('Foo').keep_if{|s| s.name == 'bar'}.first
    expect(sugg.parameters).to eq(['baz:', "boo: 'boo'"])
  end

  it "recognizes rebased namespaces" do
    code = %(
      class Foo
        class ::Bar
          def baz
          end
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    expect(api_map.namespaces.to_a).to eq(['Foo', 'Bar'])
    sugg = api_map.get_methods('Bar')
    expect(sugg.map(&:to_s)).to include('baz')
  end

  it "collects symbol pins" do
    code = %(
      x = :foo
      class Bar
        autoload :Baz, 'baz'
        initiate :bang
      end
      puts :bong
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    syms = api_map.get_symbols.map(&:name)
    expect(syms).to include(':foo')
    expect(syms).to include(':Baz')
    expect(syms).to include(':bang')
    expect(syms).to include(':bong')
  end

  it "collects superclass methods" do
    code = %(
      class Foo
        def foo_func
        end
      end
      class Bar < Foo
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    meths = api_map.get_methods('Bar')
    expect(meths.map(&:to_s)).to include('foo_func')
  end

  it "collects superclass methods from yardocs" do
    code = %(
      class Foo < String
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    meths = api_map.get_methods('Foo')
    expect(meths.map(&:to_s)).to include('upcase')
  end

  it "includes params in suggestions" do
    code = %(
      class Foo
        # @param baz [String]
        def bar baz
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    meth = api_map.get_methods('Foo').select{|s| s.name == 'bar'}.first
    expect(meth.parameters).to eq(['baz'])
  end

  it "includes restarg in suggestions" do
    code = %(
      class Foo
        def bar *baz
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    meth = api_map.get_methods('Foo').select{|s| s.name == 'bar'}.first
    expect(meth.parameters).to eq(['*baz'])
  end

  it "gets instance methods from modules" do
    code = %(
      module Foo
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    meths = api_map.get_methods('Foo').map(&:to_s)
    expect(meths).to include('bar')
  end

  it "detects attribute return types from tags" do
    code = %(
      class Foo
        # @return [String]
        attr_reader :bar
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    sugg = api_map.get_methods('Foo').select{|s| s.name == 'bar'}.first
    expect(sugg.return_type).to eq('String')
  end

  it "rebuilds the namespace map when processing virtual sources" do
    code = %(
      class Foo
      end
    )
    api_map = Solargraph::ApiMap.new
    3.times do
      api_map.virtualize_string(code, 'file.rb')
      sugg = api_map.get_path_suggestions('Foo')
      expect(sugg.length).to eq(1)
    end
  end

  it "handles nested namespaces" do
    code = %(
      module Foo
        module Bar
          class Baz
          end
        end
        module Bar2
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    suggestions = api_map.get_constants('Foo::Bar').map(&:path)
    expect(suggestions).to include('Foo::Bar::Baz')
    expect(suggestions).not_to include('Foo::Bar')
    expect(suggestions).not_to include('Foo')
    expect(suggestions).not_to include('Foo::Bar2')
    suggestions = api_map.get_constants('Bar', 'Foo').map(&:path)
    expect(suggestions).to include('Foo::Bar::Baz')
    expect(suggestions).not_to include('Foo::Bar')
    expect(suggestions).not_to include('Foo')
    expect(suggestions).not_to include('Foo::Bar2')
    suggestions = api_map.get_constants('', 'Foo::Bar').map(&:path)
    expect(suggestions).to include('Foo::Bar')
    expect(suggestions).to include('Foo::Bar::Baz')
    expect(suggestions).to include('Foo::Bar2')
  end

  # @todo This is invalid. Methods for returning pins should always return
  #   all the pins they find.
  # it "gets unique instance variable names" do
  #   code = %(
  #     class Foo
  #       def bar
  #         @bar = 'bar'
  #       end
  #       def baz
  #         @bar = 'baz'
  #       end
  #     end
  #   )
  #   api_map = Solargraph::ApiMap.new
  #   api_map.virtualize_string(code, 'file.rb')
  #   suggestions = api_map.get_instance_variable_pins('Foo', :instance)
  #   expect(suggestions.length).to eq(1)
  # end

  it "accepts nil instance variable assignments without other options" do
    code = %(
      class Foo
        def bar
          @bar = nil
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    suggestions = api_map.get_instance_variable_pins('Foo', :instance)
    expect(suggestions.length).to eq(1)
  end

  # @todo This might need to change or go. Non-nil assignment means little
  #   to the ApiMap when the variable doesn't have a type tag, because the
  #   Probe is now responsible for inferring signatures.
  # it "prefers non-nil instance variable assignments" do
  #   code = %(
  #     class Foo
  #       def bar
  #         @bar = nil
  #       end
  #       def baz
  #         @bar = 'baz'
  #       end
  #     end
  #   )
  #   api_map = Solargraph::ApiMap.new
  #   api_map.virtualize_string(code, 'file.rb')
  #   pins = api_map.get_instance_variable_pins('Foo', :instance)
  #   expect(suggestions.length).to eq(2)
  #   type = api_map.probe.infer_signature_type('@bar', pins[0].context)
  #   expect(type).to eq('String')
  #   # expect(suggestions[0].return_type).to eq('String')
  # end

  it "accepts nil instance variable assignments with @type tags" do
    code = %(
      class Foo
        def bar
          # @type [Array]
          @bar = nil
        end
        def baz
          @bar = 'baz' # Notice the first assignment is Array, not String
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    suggestions = api_map.get_instance_variable_pins('Foo', :instance)
    expect(suggestions.length).to eq(2)
    expect(suggestions[0].return_type).to eq('Array')
  end

  it "documents local code objects" do
    code = %(
      # My Foobar class
      class Foobar
        # My baz method
        def baz(one, two)
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    docs = api_map.document('Foobar')
    expect(docs.length).to eq(1)
    expect(docs[0].docstring.all).to include('My Foobar class')
    docs = api_map.document('Foobar#baz')
    expect(docs.length).to eq(1)
    expect(docs[0].docstring.all).to include('My baz method')
  end

  it "documents attributes" do
    code = %(
      class Foobar
        # @return [Array]
        attr_reader :baz
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(code, 'file.rb')
    docs = api_map.document('Foobar#baz')
    expect(docs.length).to eq(1)
    expect(docs[0].tag(:return).types[0]).to eq('Array')
  end

  # @todo ApiMap tests shouldn't care about CodeMap
  # it "updates required paths from virtual sources" do
  #   api_map = Solargraph::ApiMap.new
  #   code_map = Solargraph::CodeMap.new(code: %(
  #     require 'parser'
  #     P
  #   ), api_map: api_map)
  #   sugg = code_map.suggest_at(code_map.get_offset(2, 7)).map(&:to_s)
  #   expect(sugg).to include('Parser')
  # end

  it "detects constant visibility" do
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      module Foobar
        PUBLIC_CONST = ''
        PRIVATE_CONST = ''
        class PublicClass
        end
        class PrivateClass
        end
        private_constant :PRIVATE_CONST
        private_constant :PrivateClass
      end
    ), 'file.rb')
    sugg = api_map.get_constants('Foobar', '').map(&:to_s)
    expect(sugg).to include('PUBLIC_CONST')
    expect(sugg).to include('PublicClass')
    expect(sugg).not_to include('PRIVATE_CONST')
    expect(sugg).not_to include('PrivateClass')
    sugg = api_map.get_constants('', 'Foobar').map(&:to_s)
    expect(sugg).to include('PUBLIC_CONST')
    expect(sugg).to include('PublicClass')
    expect(sugg).to include('PRIVATE_CONST')
    expect(sugg).to include('PrivateClass')
  end

  # @todo No longer valid. The pins don't need to pick up the return type from
  #   the superclass. Instead, completion returns both pins and type inference
  #   uses the first method that returns a type.
  # it "derives method return types from superclasses" do
  #   api_map = Solargraph::ApiMap.new
  #   api_map.virtualize_string(%(
  #     class Foo
  #       # @return [String]
  #       def ghost
  #       end
  #     end
  #     class Bar < Foo
  #       def ghost
  #       end
  #     end
  #   ), 'file.rb')
  #   sugg = api_map.get_path_suggestions('Bar#ghost')
  #   expect(sugg.first).not_to be(nil)
  #   expect(sugg.first.return_type).to eq('String')
  # end

  it "includes extended modules in method suggestions" do
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      module More
        def more_method
        end
      end

      class Foobar
        extend More
      end
    ), 'file.rb')
    sugg = api_map.get_methods('Foobar', scope: :class).map(&:to_s)
    expect(sugg).to include('more_method')
  end

  # @todo This spec may not apply anymore. Although CodeMap#suggest_at should
  #   not return operators, the ApiMap needs them to identify signatures like
  #   Array.[].
  # it "does not return operators in method suggestions" do
  #   api_map = Solargraph::ApiMap.new
  #   sugg = api_map.get_instance_methods(Array).map(&:to_s)
  #   expect(sugg).not_to include('[]')
  # end

  it "rebuilds maps from file changes" do
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      class Foobar
        def baz
        end
      end
    ), 'file.rb')
    sugg = api_map.get_methods('Foobar').map(&:to_s)
    expect(sugg).to include('baz')
    api_map.virtualize_string(%(
      class Foobar
        def boo
        end
      end
    ), 'file.rb')
    sugg = api_map.get_methods('Foobar').map(&:to_s)
    expect(sugg).to include('boo')
    expect(sugg).not_to include('baz')
  end

  it "detects extended methods in the global namespace" do
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      module Foobar
        def baz
        end
      end
      extend Foobar
    ), 'file.rb')
    sugg = api_map.get_methods('').map(&:to_s)
    expect(sugg).to include('baz')
  end

  it "detects included methods in the global namespace" do
    api_map = Solargraph::ApiMap.new
    api_map.virtualize_string(%(
      module Foobar
        def baz
        end
      end
      include Foobar
    ), 'file.rb')
    sugg = api_map.get_methods('').map(&:to_s)
    expect(sugg).to include('baz')
  end

  # @todo Return types are not modified by resolution. Qualification of
  #   namespaces is handled elsewhere.
  # it "resolves fully qualified namespaces from @return tags" do
  #   api_map = Solargraph::ApiMap.new
  #   api_map.virtualize_string(%(
  #     class Foobar
  #       class Bazbar
  #       end
  #       # @return [Bazbar]
  #       def get_bazbar;end
  #     end
  #   ), 'file.rb')
  #   sugg = api_map.get_methods('Foobar').select{|s| s.name == 'get_bazbar'}.first
  #   expect(sugg).not_to be(nil)
  #   # sugg.resolve api_map
  #   expect(sugg.return_type).to eq('Foobar::Bazbar')
  # end

  # @todo ApiMap#identify may be deprecated
  # it "detects method parameter return types from @param tags" do
  #   api_map = Solargraph::ApiMap.new
  #   source = Solargraph::Source.load_string(%(
  #     class Foo
  #       # @param baz [Hash]
  #       def bar baz
  #         baz
  #       end
  #     end
  #   ), 'file.rb')
  #   api_map.virtualize source
  #   fragment = source.fragment_at(4, 11)
  #   pin = api_map.identify(fragment).first
  #   expect(pin.variable?).to be(true)
  #   expect(pin.name).to eq('baz')
  #   expect(pin.return_type).to eq('Hash')
  # end

  it "detects methods defined in the global namespace" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string(%(
      def global_method
      end
    ), 'file.rb')
    api_map.virtualize source
    meths = api_map.get_methods('').map(&:name)
    expect(meths).to include('global_method')
  end

  # @todo ApiMap#identify may be deprecated
  # it "detects block parameter return types from @yieldparam tags" do
  #   api_map = Solargraph::ApiMap.new
  #   source = Solargraph::Source.load_string(%(
  #     # @yieldparam [File]
  #     def iterate
  #     end
  #     iterate do |f|
  #       f
  #     end
  #   ), 'file.rb')
  #   api_map.virtualize source
  #   fragment = source.fragment_at(5, 9)
  #   pin = api_map.identify(fragment).first
  #   expect(pin.variable?).to be(true)
  #   expect(pin.name).to eq('f')
  #   expect(pin.return_type).to eq('File')
  # end

  # @todo ApiMap#identify may be deprecated
  # it "detects block parameter return types from core methods" do
  #   api_map = Solargraph::ApiMap.new
  #   source = Solargraph::Source.load_string(%(
  #     x = String.new.split
  #     x.each do |s|
  #       s
  #     end
  #   ), 'file.rb')
  #   api_map.virtualize source
  #   fragment = source.fragment_at(3, 9)
  #   pin = api_map.identify(fragment).first
  #   expect(pin.variable?).to be(true)
  #   expect(pin.name).to eq('s')
  #   expect(pin.return_type).to eq('String')
  # end

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
    result = api_map.complete(fragment).pins.map(&:name)
    expect(result.length).to eq(1)
    expect(result).to include('Bar')
    fragment = source.fragment_at(5, 11)
    result = api_map.complete(fragment).pins.map(&:name)
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
    items = api_map.complete(fragment).pins.map(&:name)
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
    items = api_map.complete(fragment).pins.map(&:path)
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
    cmp = api_map.complete(fragment)
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
    names = api_map.complete(fragment).pins.map(&:name)
    expect(names).to include('String')
  end

  it "completes literal strings" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("'string'._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 9)
    paths = api_map.complete(fragment).pins.map(&:path)
    expect(paths).to include('String#upcase')
  end

  it "completes literal arrays" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("[]._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 3)
    paths = api_map.complete(fragment).pins.map(&:path)
    expect(paths).to include('Array#length')
  end

  it "completes literal hashes" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("{}._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 3)
    paths = api_map.complete(fragment).pins.map(&:path)
    expect(paths).to include('Hash#has_key?')
  end

  it "completes literal integers" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("1._")
    api_map.virtualize source
    fragment = source.fragment_at(0, 2)
    paths = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
    expect(names).to include('split')
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
    paths = api_map.define(fragment).map(&:path)
    expect(paths).to include('String#split')
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
    paths = api_map.signify(fragment).map(&:path)
    expect(paths).to include('String#split')
  end

  it "adds local variables to completion items" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.load_string("lvar = 'foo'\nl")
    api_map.virtualize source
    fragment = source.fragment_at(1, 1)
    names = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
    expect(names).to include('$foo')
  end

  it "infers global variable types" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      $foo = 'foo'
    ))
    api_map.virtualize source
    fragment = source.fragment_at(1, 7)
    pin = api_map.define(fragment).first
    expect(pin.return_type).to eq('String')
  end

  it "filters for methods in signify" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      x = 'string'
      x()
    ))
    api_map.virtualize source
    fragment = source.fragment_at(2, 8)
    pins = api_map.signify(fragment)
    expect(pins).to be_empty
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
    api_map.virtualize source
    fragment = source.fragment_at(2, 0)
    names = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
    expect(names).not_to include('private')
    expect(names).not_to include('module_function')
  end

  it "maps methods scoped with module_function" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
        module_function
        def bar
        end
      end
      ))
    api_map.virtualize source
    class_meths = api_map.get_methods('Foo', scope: :class, visibility: [:public]).map(&:name)
    expect(class_meths).to include('bar')
    class_meths = api_map.get_methods('Foo', scope: :instance, visibility: [:private]).map(&:name)
    expect(class_meths).to include('bar')
  end

  it "maps methods scoped defined inside module_function" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
        module_function def bar
        end
        def baz
        end
      end
      ))
    api_map.virtualize source
    class_meths = api_map.get_methods('Foo', scope: :class, visibility: [:public]).map(&:name)
    expect(class_meths).to include('bar')
    class_meths = api_map.get_methods('Foo', scope: :instance, visibility: [:private]).map(&:name)
    expect(class_meths).to include('bar')
    class_meths = api_map.get_methods('Foo', scope: :instance, visibility: [:public]).map(&:name)
    expect(class_meths).to include('baz')
  end

  it "maps methods scoped in module_function arguments" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
        def bar
        end
        def baz
        end
        module_function :bar
      end
      ))
    api_map.virtualize source
    class_meths = api_map.get_methods('Foo', scope: :class, visibility: [:public]).map(&:name)
    expect(class_meths).to include('bar')
    class_meths = api_map.get_methods('Foo', scope: :instance, visibility: [:private]).map(&:name)
    expect(class_meths).to include('bar')
    class_meths = api_map.get_methods('Foo', scope: :instance, visibility: [:public]).map(&:name)
    expect(class_meths).to include('baz')
  end

  it "understands `extend self`" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      module Foo
        extend self
        def bar
        end
      end
      ))
    api_map.virtualize source
    meths = api_map.get_methods('Foo', scope: :class).map(&:name)
    expect(meths).to include('bar')
  end

  it "filters completion results based on the current word" do
    api_map = Solargraph::ApiMap.new
    source = Solargraph::Source.new(%(
      re
      ))
    api_map.virtualize source
    fragment = source.fragment_at(1, 8)
    names = api_map.complete(fragment).pins.map(&:name)
    expect(names).to include('rescue')
    expect(names).not_to include('raise')
    fragment = source.fragment_at(1, 7)
    names = api_map.complete(fragment).pins.map(&:name)
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
    names = api_map.complete(fragment).pins.map(&:name)
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
    pins = api_map.complete(fragment).pins
    expect(pins.length).to eq(1)
    expect(pins.first.name).to eq('@@foo')
    expect(pins.first.return_type).to eq('String')
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
    pins = api_map.define(fragment)
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
    pins = api_map.define(fragment)
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo.meth1')
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
    cmp = api_map.complete(fragment)
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
    cmp = api_map.complete(fragment)
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
    cmp = api_map.complete(fragment)
    names = cmp.pins.map(&:name)
    expect(names).to include('upcase')
  end
end
