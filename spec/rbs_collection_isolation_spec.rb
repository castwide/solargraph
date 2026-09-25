# frozen_string_literal: true

# Two workspace folders open in one editor, each with its own RBS collection.
# ApiMap.load_with_cache is the entry point an editor reaches for, and it
# caches whatever the folder needs before answering, so these hold regardless
# of how the gem pins are stored underneath.
describe Solargraph::ApiMap do
  let(:overridden) { File.join('spec', 'fixtures', 'rbs-collection-override') }
  let(:plain) { File.join('spec', 'fixtures', 'rbs-collection-absent') }

  # The collection fixture declares this as Integer; the gem itself does not.
  # @param directory [String]
  # @return [Array<String>]
  def prepare_stdio_server_types directory
    described_class.load_with_cache(directory, nil)
                   .get_path_pins('Backport.prepare_stdio_server')
                   .map { |pin| pin.return_type.to_s }
  end

  it 'serves a workspace the types its own RBS collection declares' do
    expect(prepare_stdio_server_types(overridden)).to include(a_string_including('Integer'))
  end

  it 'does not serve a workspace the types held for another' do
    prepare_stdio_server_types(overridden)

    expect(prepare_stdio_server_types(plain)).not_to include(a_string_including('Integer'))
  end
end
