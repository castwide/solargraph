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
    methods = @api_map.get_instance_methods("Class1")
    expect(methods.map(&:to_s)).to include('bar')
    expect(methods.map(&:to_s)).not_to include('baz')
  end

  it "finds included instance methods" do
    methods = @api_map.get_instance_methods("Class1")
    expect(methods.map(&:to_s)).to include('module1_method')
  end

  it "finds superclass instance methods" do
    methods = @api_map.get_instance_methods("Class2")
    expect(methods.map(&:to_s)).to include('bar')
    expect(methods.map(&:to_s)).to include('module1_method')
  end

  it "finds singleton methods" do
    methods = @api_map.get_methods("Class1")
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

  it "finds class instance variables" do
    vars = @api_map.get_instance_variables("Class1", scope: :class)
    expect(vars.map(&:to_s)).to include('@baz')
    expect(vars.map(&:to_s)).not_to include('@bar')
  end

  it "finds attr_read methods" do
    methods = @api_map.get_instance_methods("Class1")
    expect(methods.map(&:to_s)).to include('read_foo')
    expect(methods.map(&:to_s)).not_to include('read_foo=')
  end

  it "finds attr_write methods" do
    methods = @api_map.get_instance_methods("Class1")
    expect(methods.map(&:to_s)).to include('write_foo=')
    expect(methods.map(&:to_s)).not_to include('write_foo')
  end

  it "finds attr_accessor methods" do
    methods = @api_map.get_instance_methods("Class1")
    expect(methods.map(&:to_s)).to include('access_foo')
    expect(methods.map(&:to_s)).to include('access_foo=')
  end

  it "finds root namespaces" do
    namespaces = @api_map.namespaces_in('')
    expect(namespaces.map(&:to_s)).to include("Class1")
  end

  it "finds included namespaces" do
    namespaces = @api_map.namespaces_in('Class1')
    expect(namespaces.map(&:to_s)).to include('Module1Class')
  end

  it "finds namespaces within namespaces" do
    namespaces = @api_map.namespaces_in('Module1')
    expect(namespaces.map(&:to_s)).to include('Module1Class')
  end

  it "excludes namespaces outside of scope" do
    namespaces = @api_map.namespaces_in('')
    expect(namespaces.map(&:to_s)).not_to include('Module1Class')
  end

  it "finds instance variables in scoped classes" do
    methods = @api_map.get_instance_methods('Module1Class', 'Module1')
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

  it "finds filenames for nodes" do
    nodes = @api_map.get_namespace_nodes('Class1')
    expect(@api_map.get_filename_for(nodes.first)).to eq('file.rb')
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
    suggestions = api_map.get_instance_methods('Foo', '', visibility: [:public])
    expect(suggestions.map(&:to_s)).to include('bar')
    expect(suggestions.map(&:to_s)).not_to include('baz')
    suggestions = api_map.get_instance_methods('Foo', '', visibility: [:private])
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
end
