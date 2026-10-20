# frozen_string_literal: true

describe Solargraph::Source::NodeMap do
  let(:source) do
    Solargraph::Source.load_string(%(
      class Example
        class_call

        def foo
          instance_call :boo
        end
      end
    ))
  end

  let(:node_map) { described_class.new(source.node) }

  it 'returns send nodes' do
    puts node_map.find_by_type(:send).inspect
  end
end
