# frozen_string_literal: true

describe Solargraph::Parser::Walker::BaseProcessor do
  def walk code
    Solargraph::Parser::Walker.new(Solargraph::Parser.parse(code)).walk!
  end

  let(:events) { [] }

  after { Solargraph::Parser::Walker.deregister(processor_class) }

  describe '.on_node_type' do
    context 'with a method name' do
      let(:processor_class) do
        captured = events
        Class.new(described_class) do
          on_node_type :sym, :handle_sym

          define_method(:handle_sym) { captured << node.children.first }
        end
      end

      it 'calls the method for nodes of that type' do
        processor_class
        walk('foo(:a, "b", :c)')
        expect(events).to eq(%i[a c])
      end
    end

    context 'with a block' do
      let(:processor_class) do
        captured = events
        Class.new(described_class) do
          on_node_type(:sym) { captured << node.children.first }
        end
      end

      it 'calls the block for nodes of that type' do
        processor_class
        walk('foo(:a, "b", :c)')
        expect(events).to eq(%i[a c])
      end
    end
  end

  describe '.on_node_type_leave' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_type(:send) { captured << [:enter, node.children[1]] }
        on_node_type_leave(:send) { captured << [:leave, node.children[1]] }
      end
    end

    it 'calls the handler after the children are walked' do
      processor_class
      walk('foo(bar)')
      expect(events).to eq([%i[enter foo], %i[enter bar], %i[leave bar], %i[leave foo]])
    end
  end

  describe '.on_node_pattern_enter' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_pattern_enter('(send nil? :attribute (sym $_) (const nil? $_))') do |name, type|
          captured << [name, type]
        end
      end
    end

    it 'calls the handler with the captures of matching nodes' do
      processor_class
      walk(<<~RUBY)
        attribute :name, String
        attribute 'name', String
        other :name, String
      RUBY
      expect(events).to eq([%i[name String]])
    end

    context 'with a union pattern' do
      let(:processor_class) do
        captured = events
        Class.new(described_class) do
          on_node_pattern_enter('{(send nil? $:foo) (lvasgn $_ _)}') { |name| captured << name }
        end
      end

      it 'matches each node type in the union' do
        processor_class
        walk('foo; bar = 1')
        expect(events).to eq(%i[foo bar])
      end
    end

    context 'with send patterns limited to method names' do
      let(:processor_class) do
        captured = events
        Class.new(described_class) do
          on_node_pattern_enter('(send nil? ${:foo :bar})') { |name| captured << [:named, name] }
          on_node_pattern_enter('(send nil? $_)') { |name| captured << [:any, name] }
        end
      end

      it 'matches only the sends with those method names' do
        processor_class
        walk('foo; baz; bar')
        expect(events).to eq([%i[named foo], %i[any foo], %i[any baz], %i[named bar], %i[any bar]])
      end
    end

    context 'with a pattern that matches any node type' do
      let(:processor_class) do
        captured = events
        Class.new(described_class) do
          on_node_pattern_enter('(_ :marker ...)') { captured << node.type }
        end
      end

      it 'tries every node' do
        processor_class
        walk('foo(:marker); x = :marker; :marker')
        expect(events).to eq(%i[sym sym sym])
      end
    end
  end

  describe '.on_node_pattern_leave' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_pattern_enter('(send nil? $_)') { |name| captured << [:enter, name] }
        on_node_pattern_leave('(send nil? $_ ...)') { |name| captured << [:leave, name] }
      end
    end

    it 'calls the handler with the captures after the children are walked' do
      processor_class
      walk('foo(bar)')
      expect(events).to eq([%i[enter bar], %i[leave bar], %i[leave foo]])
    end
  end

  describe '#process_children' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_type :kwbegin do
          process_children region.update(visibility: :private)
        end

        on_node_type(:send) { captured << [node.children[1], region.visibility] }
      end
    end

    it 'walks the children with the given region' do
      processor_class
      walk('begin; bar; end; baz')
      expect(events).to eq([%i[bar private], %i[baz public]])
    end
  end

  describe '#skip_children' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_type(:kwbegin) { skip_children }
        on_node_type(:send) { captured << node.children[1] }
      end
    end

    it 'does not walk the children' do
      processor_class
      walk('begin; bar; end; baz')
      expect(events).to eq([:baz])
    end
  end

  describe '#walk' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_type :kwbegin do
          skip_children
          walk node.updated(:send, [nil, :synthetic])
        end

        on_node_type(:send) { captured << node.children[1] }
      end
    end

    it 'dispatches arbitrary nodes through the walker' do
      processor_class
      walk('begin; bar; end')
      expect(events).to eq([:synthetic])
    end
  end

  describe 'instances' do
    let(:processor_class) do
      captured = events
      Class.new(described_class) do
        on_node_type(:send) { @entered = node }
        on_node_type_leave(:send) { captured << @entered.equal?(node) }
      end
    end

    it 'shares one processor instance between the enter and leave handlers of a node' do
      processor_class
      walk('foo(bar)')
      expect(events).to eq([true, true])
    end
  end
end
