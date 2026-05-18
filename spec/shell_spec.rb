# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  let(:shell) { described_class.new }

  describe 'rbs' do
    let(:api_map) { instance_double(Solargraph::ApiMap) }

    before do
      allow(shell).to receive(:`)
      allow(Solargraph::ApiMap).to receive(:load).and_return(api_map)
      allow(api_map).to receive(:source_maps).and_return(source_maps)
    end

    context 'without inference' do
      let(:source_maps) { [] }

      it 'invokes sord' do
        capture_both do
          shell.options = { filename: 'foo.rbs' }
          shell.rbs
        end
        expect(shell)
          .to have_received(:`)
          .with("sord #{Dir.pwd}/sig/foo.rbs --rbs --no-regenerate")
      end
    end

    context 'with inference' do
      let(:source_maps) { [source_map] }
      let(:source_map) { instance_double(Solargraph::SourceMap) }
      let(:pin) do
        instance_double(Solargraph::Pin::Method,
                        namespace: 'My::Namespace', path: 'My::Namespace#foo',
                        visibility: :public,
                        parameters: [],
                        scope: :instance,
                        location: nil,
                        name: 'foo',
                        class: Solargraph::Pin::Method,
                        return_type: Solargraph::ComplexType::UNDEFINED)
      end

      it 'infers unknown types on pins' do
        allow(source_map).to receive(:pins).and_return([pin])
        allow(pin).to receive_messages(typify: Solargraph::ComplexType.parse('String'),
                                       docstring: YARD::Docstring.new(''))
        allow(pin).to receive(:code_object).and_return(nil)
        capture_both do
          shell.options = { filename: 'foo.rbs', inference: true }
          shell.rbs
        end
        expect(pin).to have_received(:typify)
      end
    end
  end
end
