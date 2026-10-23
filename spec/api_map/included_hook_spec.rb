# frozen_string_literal: true

describe Solargraph::ApiMap, '#get_method_stack' do
  let(:api_map) { described_class.new.map(Solargraph::Source.load_string(code, 'test.rb')) }

  # @param fqns [String]
  # @param name [String]
  # @param scope [Symbol]
  # @return [Array<String>]
  def stack_paths fqns, name, scope
    api_map.get_method_stack(fqns, name, scope: scope).map(&:path)
  end

  context 'with base.extend ClassMethods in a self.included hook' do
    let(:code) do
      %(
        module Outer
          module Mixin
            def self.included(base)
              base.extend ClassMethods
            end

            module ClassMethods
              def from_class_methods; end
            end
          end
        end

        class Includer
          include Outer::Mixin
        end

        class Subclass < Includer; end
      )
    end

    it 'adds the extended module to the includer class methods' do
      expect(stack_paths('Includer', 'from_class_methods', :class))
        .to eq(['Outer::Mixin::ClassMethods#from_class_methods'])
    end

    it 'adds the extended module to subclasses of the includer' do
      expect(stack_paths('Subclass', 'from_class_methods', :class))
        .to eq(['Outer::Mixin::ClassMethods#from_class_methods'])
    end

    it 'does not add the extended module to instance methods' do
      expect(stack_paths('Includer', 'from_class_methods', :instance)).to be_empty
    end
  end

  context 'with a hook parameter not named base' do
    let(:code) do
      %(
        module Mixin
          def self.included(klass)
            super
            klass.extend ClassMethods
          end

          module ClassMethods
            def from_class_methods; end
          end
        end

        class Includer
          include Mixin
        end
      )
    end

    it 'adds the extended module to the includer class methods' do
      expect(stack_paths('Includer', 'from_class_methods', :class))
        .to eq(['Mixin::ClassMethods#from_class_methods'])
    end
  end

  context 'with include, prepend and extend self on the hook parameter' do
    let(:code) do
      %(
        module Mixin
          def self.included(base)
            base.include Included
            base.prepend Prepended
            base.extend self
          end

          def from_self; end

          module Included
            def from_included; end
          end

          module Prepended
            def from_prepended; end
          end
        end

        class Includer
          include Mixin
        end
      )
    end

    it 'adds included modules to the includer instance methods' do
      expect(stack_paths('Includer', 'from_included', :instance)).to eq(['Mixin::Included#from_included'])
    end

    it 'adds prepended modules to the includer instance methods' do
      expect(stack_paths('Includer', 'from_prepended', :instance)).to eq(['Mixin::Prepended#from_prepended'])
    end

    it 'adds the hook module itself to the includer class methods' do
      expect(stack_paths('Includer', 'from_self', :class)).to eq(['Mixin#from_self'])
    end
  end

  context 'with send and public_send on the hook parameter' do
    let(:code) do
      %(
        module Mixin
          def self.included(base)
            base.send(:include, Included)
            base.public_send(:extend, ClassMethods)
          end

          module Included
            def from_included; end
          end

          module ClassMethods
            def from_class_methods; end
          end
        end

        class Includer
          include Mixin
        end
      )
    end

    it 'adds modules included through send' do
      expect(stack_paths('Includer', 'from_included', :instance)).to eq(['Mixin::Included#from_included'])
    end

    it 'adds modules extended through public_send' do
      expect(stack_paths('Includer', 'from_class_methods', :class))
        .to eq(['Mixin::ClassMethods#from_class_methods'])
    end
  end

  context 'with mixins that do not apply to the includer' do
    let(:code) do
      %(
        module Mixin
          def self.included(base)
            other = Object
            other.extend Unrelated
            helper = Unrelated
            base.extend helper
            base.send(method_name, Unrelated)
            base.send(:define_method, :foo) {}
          end

          def self.extended(base)
            base.extend Unrelated
          end

          module Unrelated
            def unrelated; end
          end
        end

        class Includer
          include Mixin
        end
      )
    end

    it 'ignores receivers other than the hook parameter, non-literal send and other hooks' do
      expect(stack_paths('Includer', 'unrelated', :class)).to be_empty
    end

    it 'maps no included mixins' do
      pins = Solargraph::SourceMap.load_string(code, 'test.rb').pins
      expect(pins.grep(Solargraph::Pin::Reference::IncludedMixin)).to be_empty
    end

    it 'ignores send of methods other than mixins' do
      expect(stack_paths('Includer', 'unrelated', :instance)).to be_empty
    end
  end
end
