# frozen_string_literal: true

describe Solargraph::Pin::Block do
  let(:foo) { instance_double(Solargraph::Pin::Parameter, name: 'foo') }
  let(:bar) { instance_double(Solargraph::Pin::Parameter, name: 'bar') }
  let(:block) { instance_double(Solargraph::Pin::Parameter, name: 'block') }

  it 'strips prefixes from parameter names' do
    pin = described_class.new(args: [foo, bar, block])
    expect(pin.parameter_names).to eq(%w[foo bar block])
  end

  it 'reports the namespace of the method enclosing the block' do
    namespace = Solargraph::Pin::Namespace.new(name: 'Foo', type: :class)
    method = Solargraph::Pin::Method.new(closure: namespace, name: 'bar', scope: :instance)
    pin = described_class.new(closure: method)
    expect(pin.method_namespace).to eq('Foo')
  end
end
