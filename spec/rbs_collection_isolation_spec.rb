# frozen_string_literal: true

# Two workspace folders open in one editor, each with its own RBS collection.
# ApiMap.load_with_cache is the entry point an editor reaches for, and it
# caches whatever the folder needs before answering, so these hold regardless
# of how the gem pins are stored underneath.
describe Solargraph::ApiMap do
  let(:overridden) { File.join('spec', 'fixtures', 'rbs-collection-override') }
  let(:plain) { File.join('spec', 'fixtures', 'rbs-collection-absent') }
  let(:revision_a) { File.join('spec', 'fixtures', 'rbs-collection-revision-a') }
  let(:revision_b) { File.join('spec', 'fixtures', 'rbs-collection-revision-b') }

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

  # Both of these resolve the gem and differ only in the collection revision
  # they pin, which is the pair an editor actually holds open. Their entries
  # are already separate on disk; what decides the answer is whether the gem
  # is looked up by name and version alone.
  it 'serves each workspace the collection revision it pins' do
    expect(prepare_stdio_server_types(revision_a)).to include(a_string_including('Integer'))
    expect(prepare_stdio_server_types(revision_b)).to include(a_string_including('Float'))
  end
end
