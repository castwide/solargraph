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
    @api_map.append_source(code, 'file.rb')
  end

  it "finds instance methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('bar')
    expect(methods.map(&:to_s)).not_to include('baz')
  end

  it "finds included instance methods" do
    methods = @api_map.get_methods("Class1")
    expect(methods.map(&:to_s)).to include('module1_method')
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
    vars = @api_map.get_instance_variables("Class1")
    expect(vars.map(&:to_s)).to include('@bar')
    expect(vars.map(&:to_s)).not_to include('@baz')
  end

  it "finds instance variables inside blocks" do
    vars = @api_map.get_instance_variables("Class1")
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
    api_map.append_source(code, 'file.rb')
    vars = api_map.get_instance_variables('', :class).map(&:to_s)
    expect(vars).to include('@foobar')
    expect(vars).not_to include('@not1')
    expect(vars).not_to include('@not2')
  end

  it "finds class instance variables" do
    vars = @api_map.get_instance_variables("Class1", :class)
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

  it "finds instance variables in scoped classes" do
    # methods = @api_map.get_instance_methods('Module1Class', 'Module1')
    methods = @api_map.get_type_methods('Module1Class', 'Module1')
    expect(methods.map(&:to_s)).to include('module1class_method')
  end

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

  it "infers instance variable classes" do
    cls = @api_map.infer_instance_variable('@bar', 'Class1', :instance)
    expect(cls).to eq('String')
  end

  it "infers local class from [Class].new method" do
    cls = @api_map.infer_signature_type('Class1.new', '')
    expect(cls).to eq('Class1')
    cls = @api_map.infer_signature_type('Module1::Module1Class.new', '')
    expect(cls).to eq('Module1::Module1Class')
    cls = @api_map.infer_signature_type('Module1Class.new', 'Module1')
    expect(cls).to eq('Module1::Module1Class')
  end

  it "infers core class from [Class].new method" do
    cls = @api_map.infer_signature_type('String.new', '', scope: :class)
    expect(cls).to eq('String')
  end

  it "checks visibility of instance methods" do
    code = %(
      class Foo
        def bar;end
        private
        def baz;end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    suggestions = api_map.get_methods('Foo', visibility: [:public])
    expect(suggestions.map(&:to_s)).to include('bar')
    expect(suggestions.map(&:to_s)).not_to include('baz')
    suggestions = api_map.get_methods('Foo', visibility: [:private])
    expect(suggestions.map(&:to_s)).not_to include('bar')
    expect(suggestions.map(&:to_s)).to include('baz')
  end

  it "avoids infinite loops from variable assignments that reference themselves" do
    code = %(
      @foo = @foo
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_instance_variable('@foo', '', :class)
    expect(type).to be(nil)
  end

  it "recognizes self in instance scope" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('self', 'Foo', scope: :instance)
    expect(type).to eq('Foo')
  end

  it "recognizes self in instance method chain" do
    code = %(
      class Foo
        # @return [String]
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('self.bar', 'Foo', scope: :instance)
    expect(type).to eq('String')
  end

  it "recognizes self in class scope" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('self', 'Foo', scope: :class)
    expect(type).to eq('Class<Foo>')
  end

  it "recognizes self in class method chain" do
    code = %(
      class Foo
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('self.new', 'Foo', scope: :class)
    expect(type).to eq('Foo')
  end

  it "infers an instance variable type from a tag" do
    code = %(
      class Foo
        def bar
          # @type [String]
          @bar = unknown_method
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@bar', 'Foo', scope: :instance)
    expect(type).to eq('String')
  end

  it "does not infer an instance variable type in the class scope" do
    code = %(
      class Foo
        def bar
          # @type [String]
          @bar = unknown_method
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@bar', 'Foo', scope: :class)
    expect(type).to eq(nil)
  end

  it "infers a class instance variable type from a tag" do
    code = %(
      class Foo
        # @type [String]
        @bar = unknown_method
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@bar', 'Foo', scope: :class)
    expect(type).to eq('String')
  end

  it "does not infer a class instance variable type in the instance scope" do
    code = %(
      class Foo
        # @type [String]
        @bar = unknown_method
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@bar', 'Foo', scope: :instance)
    expect(type).to eq(nil)
  end

  it "infers a class variable type from a tag" do
    code = %(
      class Foo
        # @type [String]
        @@bar = unknown_method
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@@bar', 'Foo')
    expect(type).to eq('String')
  end

  it "infers a class variable type in a nil guard" do
    code = %(
      class Foo
        @@bar ||= ''
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('@@bar', 'Foo')
    expect(type).to eq('String')
  end

  it "infers a class method return type from a tag" do
    code = %(
      class Foo
        # @return [String]
        def self.bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('Foo.bar', '')
    expect(type).to eq('String')
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
    api_map.append_source(code, 'file.rb')
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
    api_map.append_source(code, 'file.rb')
    sugg = api_map.get_methods('Foo').keep_if{|s| s.name == 'bar'}.first
    expect(sugg.arguments).to eq(['baz', "boo = 'boo'"])
  end

  it "gets method keyword arguments" do
    code = %(
      class Foo
        def bar baz:, boo: 'boo'
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    sugg = api_map.get_methods('Foo').keep_if{|s| s.name == 'bar'}.first
    expect(sugg.arguments).to eq(['baz:', "boo: 'boo'"])
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
    api_map.append_source(code, 'file.rb')
    expect(api_map.namespaces).to eq(['Foo', 'Bar'])
    sugg = api_map.get_methods('Bar')
    expect(sugg.map(&:to_s)).to include('baz')
  end

  it "updates map data on refresh" do
    api_map = Solargraph::ApiMap.new
    code1 = %(
      class Foo
        # @return [String]
        def bar;end
      end
    )
    api_map.append_source(code1, 'file.rb')
    api_map.refresh
    type = api_map.infer_signature_type('Foo.new.bar', '')
    expect(type).to eq('String')
    code2 = %(
      class Foo
        # @return [Array]
        def bar;end
      end
    )
    api_map.append_source(code2, 'file.rb')
    api_map.refresh
    type = api_map.infer_signature_type('Foo.new.bar', '')
    expect(type).to eq('Array')
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
    api_map.append_source(code, 'file.rb')
    syms = api_map.get_symbols.map(&:to_s)
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
    api_map.append_source(code, 'file.rb')
    meths = api_map.get_methods('Bar')
    expect(meths.map(&:to_s)).to include('foo_func')
  end

  it "collects superclass methods from yardocs" do
    code = %(
      class Foo < String
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
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
    api_map.append_source(code, 'file.rb')
    meth = api_map.get_methods('Foo').select{|s| s.name == 'bar'}.first
    expect(meth.params).to eq(['baz [String]'])
  end

  it "includes restarg in suggestions" do
    code = %(
      class Foo
        def bar *baz
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    # @type [Solargraph::Suggestion]
    meth = api_map.get_methods('Foo').select{|s| s.name == 'bar'}.first
    expect(meth.arguments).to eq(['*baz'])
  end

  it "gets instance methods from modules" do
    code = %(
      module Foo
        def bar
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
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
    api_map.append_source(code, 'file.rb')
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
      api_map.append_source(code, 'file.rb')
      sugg = api_map.get_path_suggestions('Foo')
      expect(sugg.length).to eq(1)
    end
  end

  it "infers Kernel method types" do
    code = "gets"
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('gets', '')
    expect(type).to eq('String')
  end

  it "infers Kernel method types from namespaces" do
    code = "class Foo;end"
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    type = api_map.infer_signature_type('gets', 'Foo', scope: :class)
    expect(type).to eq('String')
    type = api_map.infer_signature_type('gets', 'Foo', scope: :instance)
    expect(type).to eq('String')
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
    api_map.append_source(code, 'file.rb')
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

  it "gets unique instance variable names" do
    code = %(
      class Foo
        def bar
          @bar = 'bar'
        end
        def baz
          @bar = 'baz'
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    suggestions = api_map.get_instance_variables('Foo', :instance)
    expect(suggestions.length).to eq(1)
  end

  it "accepts nil instance variable assignments without other options" do
    code = %(
      class Foo
        def bar
          @bar = nil
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    suggestions = api_map.get_instance_variables('Foo', :instance)
    expect(suggestions.length).to eq(1)
  end

  it "prefers non-nil instance variable assignments" do
    code = %(
      class Foo
        def bar
          @bar = nil
        end
        def baz
          @bar = 'baz'
        end
      end
    )
    api_map = Solargraph::ApiMap.new
    api_map.append_source(code, 'file.rb')
    suggestions = api_map.get_instance_variables('Foo', :instance)
    expect(suggestions.length).to eq(1)
    expect(suggestions[0].return_type).to eq('String')
  end

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
    api_map.append_source(code, 'file.rb')
    suggestions = api_map.get_instance_variables('Foo', :instance)
    expect(suggestions.length).to eq(1)
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
    api_map.append_source(code, 'file.rb')
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
    api_map.append_source(code, 'file.rb')
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
    api_map.append_source(%(
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

  it "derives method return types from superclasses" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      class Foo
        # @return [String]
        def ghost
        end
      end
      class Bar < Foo
        def ghost
        end
      end
    ), 'file.rb')
    sugg = api_map.get_path_suggestions('Bar#ghost')
    expect(sugg.first).not_to be(nil)
    expect(sugg.first.return_type).to eq('String')
  end

  it "includes extended modules in method suggestions" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
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

  # @todo Since the ApiMap relies on a Workspace, it might not make sense
  # for the ApiMap to check the filesystem for changes.
  it "detects workspace changes from modified files" do
    Dir.mktmpdir do |dir|
      File.write File.join(dir, 'test.rb'), 'puts "hello"'
      api_map = Solargraph::ApiMap.new(dir)
      expect(api_map.changed?).to eq(false)
      sleep(1)
      File.write File.join(dir, 'test.rb'), 'puts "world"'
      expect(api_map.changed?).to eq(true)
    end
  end

  # @todo Since the ApiMap relies on a Workspace, it might not make sense
  # for the ApiMap to check the filesystem for changes.
  it "detects workspace changes from new files" do
    Dir.mktmpdir do |dir|
      File.write File.join(dir, 'test.rb'), 'puts "hello"'
      api_map = Solargraph::ApiMap.new(dir)
      expect(api_map.changed?).to eq(false)
      File.write File.join(dir, 'test2.rb'), 'puts "world"'
      expect(api_map.changed?).to eq(true)
    end
  end

  # @todo Since the ApiMap relies on a Workspace, it might not make sense
  # for the ApiMap to check the filesystem for changes.
  it "detects workspace changes from deleted files" do
    Dir.mktmpdir do |dir|
      File.write File.join(dir, 'test.rb'), 'puts "hello"'
      File.write File.join(dir, 'test2.rb'), 'puts "world"'
      api_map = Solargraph::ApiMap.new(dir)
      expect(api_map.changed?).to eq(false)
      File.unlink File.join(dir, 'test2.rb')
      expect(api_map.changed?).to eq(true)
    end
  end

  it "resolves self from return tags" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      class Foo
        # @return [self]
        def bar
        end
      end
    ), 'file.rb')
    type = api_map.infer_signature_type('Foo.new.bar', '')
    expect(type).to eq('Foo')
  end

  it "resolves self from included methods" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      module Foo
        # @return [self]
        def bar
        end
      end
      class Baz
        include Foo
      end
    ), 'file.rb')
    type = api_map.infer_signature_type('Baz.new.bar', '')
    expect(type).to eq('Baz')
  end

  # @todo This spec may not apply anymore. Although CodeMap#suggest_at should
  #   not return operators, the ApiMap needs them to identify signatures like
  #   Array.[].
  # it "does not return operators in method suggestions" do
  #   api_map = Solargraph::ApiMap.new
  #   sugg = api_map.get_instance_methods(Array).map(&:to_s)
  #   expect(sugg).not_to include('[]')
  # end

  it "detects return types from macro directives" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      class Foo
        # @!macro
        #   @return [$1]
        def self.bar klass
        end
      end
      @x = Foo.bar Hash
    ), 'file.rb')
    type = api_map.infer_signature_type('@x', '')
    expect(type).to eq('Hash')
  end

  it "rebuilds maps from file changes" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      class Foobar
        def baz
        end
      end
    ), 'file.rb')
    sugg = api_map.get_methods('Foobar').map(&:to_s)
    expect(sugg).to include('baz')
    api_map.append_source(%(
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
    api_map.append_source(%(
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
    api_map.append_source(%(
      module Foobar
        def baz
        end
      end
      include Foobar
    ), 'file.rb')
    sugg = api_map.get_methods('').map(&:to_s)
    expect(sugg).to include('baz')
  end

  it "resolves fully qualified namespaces from @return tags" do
    api_map = Solargraph::ApiMap.new
    api_map.append_source(%(
      class Foobar
        class Bazbar
        end
        # @return [Bazbar]
        def get_bazbar;end
      end
    ), 'file.rb')
    sugg = api_map.get_methods('Foobar').select{|s| s.name == 'get_bazbar'}.first
    expect(sugg).not_to be(nil)
    expect(sugg.return_type).to eq('Foobar::Bazbar')
  end
end
