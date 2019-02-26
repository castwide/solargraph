describe Solargraph::ApiMap::SourceToYard do
  it "rakes sources" do
    source = Solargraph::SourceMap.load_string(%(
      module Foo
        class Bar
          def baz
          end
        end
      end
    ))
    object = Object.new
    object.extend Solargraph::ApiMap::SourceToYard
    object.rake_yard Solargraph::ApiMap::Store.new(source.pins)
    expect(object.code_object_paths.length).to eq(3)
    expect(object.code_object_paths).to include('Foo')
    expect(object.code_object_paths).to include('Foo::Bar')
    expect(object.code_object_paths).to include('Foo::Bar#baz')
  end

  it "generates docstrings" do
    source = Solargraph::SourceMap.load_string(%(
      # My foo class 描述
      class Foo
        # @return [Hash]
        def bar
        end
        # @return [Foo]
        def self.baz
        end
      end
    ))
    object = Object.new
    object.extend Solargraph::ApiMap::SourceToYard
    object.rake_yard Solargraph::ApiMap::Store.new(source.pins)
    class_object = object.code_object_at('Foo')
    expect(class_object.docstring).to eq('My foo class 描述')
    instance_method_object = object.code_object_at('Foo#bar')
    expect(instance_method_object.tag(:return).types).to eq(['Hash'])
    class_method_object = object.code_object_at('Foo.baz')
    expect(class_method_object.tag(:return).types).to eq(['Foo'])
  end

  it "generates mixins" do
    source = Solargraph::SourceMap.load_string(%(
      module Foo
        def bar
        end
      end
      class Baz
        include Foo
      end
    ))
    object = Object.new
    object.extend Solargraph::ApiMap::SourceToYard
    object.rake_yard Solargraph::ApiMap::Store.new(source.pins)
    module_object = object.code_object_at('Foo')
    class_object = object.code_object_at('Baz')
    expect(class_object.mixins).to include(module_object)
  end

  it "generates methods for attributes" do
    source = Solargraph::SourceMap.load_string(%(
      class Foo
        attr_reader :bar
        attr_writer :baz
        attr_accessor :boo
      end
    ))
    object = Object.new
    object.extend Solargraph::ApiMap::SourceToYard
    object.rake_yard Solargraph::ApiMap::Store.new(source.pins)
    expect(object.code_object_at('Foo#bar')).not_to be(nil)
    expect(object.code_object_at('Foo#bar=')).to be(nil)
    expect(object.code_object_at('Foo#baz')).to be(nil)
    expect(object.code_object_at('Foo#baz=')).not_to be(nil)
    expect(object.code_object_at('Foo#boo')).not_to be(nil)
    expect(object.code_object_at('Foo#boo=')).not_to be(nil)
  end

  it "generates method parameters" do
    source = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar baz, boo = 'boo'
        end
      end
    ))
    object = Object.new
    object.extend Solargraph::ApiMap::SourceToYard
    object.rake_yard Solargraph::ApiMap::Store.new(source.pins)
    method_object = object.code_object_at('Foo#bar')
    expect(method_object.parameters.length).to eq(2)
    expect(method_object.parameters[0]).to eq(['baz', nil])
    expect(method_object.parameters[1]).to eq(['boo', "'boo'"])
  end
end
