# frozen_string_literal: true

describe Solargraph::Pin::Block do
  let(:foo) { instance_double(Solargraph::Pin::Parameter, name: 'foo') }
  let(:bar) { instance_double(Solargraph::Pin::Parameter, name: 'bar') }
  let(:block) { instance_double(Solargraph::Pin::Parameter, name: 'block') }

  it 'strips prefixes from parameter names' do
    pin = described_class.new(args: [foo, bar, block])
    expect(pin.parameter_names).to eq(%w[foo bar block])
  end

  it 'leaves a block parameter undefined when dispatched via #send' do
    # Kernel#send's own block signature is a real splat (`(*arg ::Array) -> untyped`),
    # not a promise that one Array-typed value was yielded.
    source = Solargraph::Source.load_string(%(
      class SendDispatch
        # @param items [Array<String>]
        # @yieldparam item [String]
        # @return [void]
        def each_item(items)
          items.each { |raw| yield raw }
        end
      end

      SendDispatch.new.each_item(['a']) { |item| item }
      SendDispatch.new.send(:each_item, ['a']) { |item| item }
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new
    api_map.map source
    locals = api_map.source_map('test.rb').locals.select { |l| l.name == 'item' }
    expect(locals.length).to eq(2)
    direct, dispatched = locals
    expect(direct.typify(api_map).tag).to eq('String')
    expect(dispatched.typify(api_map)).to be_undefined
  end
end
