# frozen_string_literal: true

describe Solargraph::Parser::Walker do
  let(:events) { [] }
  let(:processor_classes) { [] }

  after { processor_classes.each { |klass| described_class.deregister(klass) } }

  def processor &block
    Class.new(described_class::BaseProcessor, &block).tap { |klass| processor_classes << klass }
  end

  def walker code
    described_class.new(Solargraph::Parser.parse(code))
  end

  it 'walks every node depth-first' do
    captured = events
    processor do
      on_node_pattern_enter('_') { captured << node.type }
    end
    walker('foo(1)').walk!
    expect(events).to eq(%i[send int])
  end

  it 'dispatches to handlers in registration order' do
    captured = events
    processor { on_node_type(:int) { captured << :first } }
    processor { on_node_pattern_enter('(int _)') { captured << :second } }
    processor { on_node_type(:int) { captured << :third } }
    walker('1').walk!
    expect(events).to eq(%i[first second third])
  end

  it 'skips the remaining enter handlers of a halted node' do
    captured = events
    processor { on_node_type(:int) { walker.halt } }
    processor do
      on_node_type(:int) { captured << :enter }
      on_node_type_leave(:int) { captured << :leave }
    end
    walker('1').walk!
    expect(events).to eq([:leave])
  end

  it 'shares context between processors' do
    captured = events
    processor { on_node_type(:array) { walker.context[:size] = node.children.size } }
    processor { on_node_type(:int) { captured << [walker.context[:size], node.children.first] } }
    walker('[1, 2]').walk!
    expect(events).to eq([[2, 1], [2, 2]])
  end

  it 'runs after walk callbacks once the walk completes' do
    captured = events
    processor do
      on_node_type(:int) { walker.on_after_walk { captured << node.children.first } }
    end
    walk = walker('[1, 2]')
    walk.walk!
    expect(events).to eq([1, 2])
  end

  describe '.deregister' do
    it 'removes the handlers of a processor for a node type' do
      captured = events
      klass = processor do
        on_node_type(:int) { captured << :int }
        on_node_type(:str) { captured << :str }
      end
      described_class.deregister(klass, :int)
      walker('[1, "a"]').walk!
      expect(events).to eq([:str])
    end

    it 'removes all handlers of a processor' do
      captured = events
      klass = processor do
        on_node_type(:int) { captured << :int }
        on_node_pattern_enter('(str _)') { captured << :str }
      end
      described_class.deregister(klass)
      walker('[1, "a"]').walk!
      expect(events).to be_empty
    end
  end
end
