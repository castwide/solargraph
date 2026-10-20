# frozen_string_literal: true

describe Solargraph::Convention::ClassDefinition do
  it 'indexes a Class.new assignment as a namespace' do
    source = Solargraph::SourceMap.load_string(%(
      module Vendor
        Specific = Class.new(StandardError) do
          # @return [Integer]
          def retry_after
            5
          end
        end
      end
    ), 'test.rb')

    pin = source.pins.find { |p| p.path == 'Vendor::Specific' }
    expect(pin).to be_a(Solargraph::Pin::Namespace)
    expect(pin.type).to be(:class)
  end

  it 'indexes an explicitly namespace-qualified Class.new assignment' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      module Vendor
      end

      Vendor::Specific = Class.new(StandardError) do
        # @return [Integer]
        def retry_after
          5
        end
      end
    ), 'test.rb')

    expect(api_map.get_methods('Vendor::Specific').map(&:name)).to include('retry_after')
  end

  it 'attaches block methods to the new class rather than the enclosing module' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      module Vendor
        Specific = Class.new(StandardError) do
          # @return [Integer]
          def retry_after
            5
          end
        end
      end
    ), 'test.rb')

    expect(api_map.get_methods('Vendor::Specific').map(&:name)).to include('retry_after')
    expect(api_map.get_methods('Vendor').map(&:name)).not_to include('retry_after')
  end

  it 'records the superclass' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      module Vendor
        Specific = Class.new(StandardError)
      end
    ), 'test.rb')

    expect(api_map.super_and_sub?('StandardError', 'Vendor::Specific')).to be(true)
    expect(api_map.get_methods('Vendor::Specific').map(&:name)).to include('message')
  end

  it 'supports a Class.new class as a superclass of another' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      module Vendor
        Base = Class.new(StandardError)
        Nested = Class.new(Base) do
          # @return [String]
          def label
            'x'
          end
        end
      end
    ), 'test.rb')

    names = api_map.get_methods('Vendor::Nested').map(&:name)
    expect(names).to include('label')
    expect(names).to include('message')
  end

  it 'handles Class.new with no superclass' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      Anon = Class.new do
        # @return [Symbol]
        def tag
          :t
        end
      end
    ), 'test.rb')

    expect(api_map.get_methods('Anon').map(&:name)).to include('tag')
  end

  it 'handles a non-constant superclass expression' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      klass = Object
      Dynamic = Class.new(klass)
    ), 'test.rb')

    expect(api_map.get_path_pins('Dynamic').first).to be_a(Solargraph::Pin::Namespace)
  end

  it 'leaves Struct.new assignments to the struct convention' do
    api_map = Solargraph::ApiMap.new
    api_map.map Solargraph::Source.load_string(%(
      # @param bar [String]
      Foo = Struct.new(:bar)
    ), 'test.rb')

    expect(api_map.get_methods('Foo').map(&:name)).to include('bar')
  end

  it 'resolves calls on a Class.new class in a typecheck' do
    checker = Solargraph::TypeChecker.load_string(%(
      module Vendor
        Specific = Class.new(StandardError) do
          # @return [Integer]
          def retry_after
            5
          end
        end
      end

      # @param e [Vendor::Specific]
      # @return [void]
      def wait_for(e)
        e.retry_after
      end
    ), 'test.rb', :strong)

    expect(checker.problems).to be_empty
  end
end
