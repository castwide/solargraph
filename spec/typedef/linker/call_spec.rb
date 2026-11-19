# frozen_string_literal: true

describe Solargraph::Typedef::Linker::Call do
  def dictionary_for code, position
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    Solargraph::Typedef::Dictionary.at(api_map, 'test.rb', position)
  end

  it 'prefers local variables to parameters' do
    code = %(
      def foo a
        a = 'foo'
        a
      end
    )

    dictionary = dictionary_for(code, [3, 8])
    receiver = dictionary.api_map.get_path_pins('#foo').first
    link = dictionary.chain.links.last
    resolved = described_class.new(dictionary, link, receiver).resolve
    expect(resolved).to be_one
    expect(resolved.first.class).to be(Solargraph::Pin::LocalVariable)
  end
end
