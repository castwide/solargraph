# frozen_string_literal: true

describe Solargraph::Typedef::Linker::Constant do
  it 'resolves absolute paths' do
    source = Solargraph::Source.load_string(%(
      module Example
        class String; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    link = Solargraph::Source::Chain::Constant.new('::String')
    dictionary = double(Solargraph::Typedef::Dictionary, api_map: api_map)
    constant = Solargraph::Typedef::Linker::Constant.new(dictionary, link, api_map.get_path_pins('Example').first)
    result = constant.resolve.first
    typeset = result.typedef_typeset
    expect(typeset.to_s).to eq('Class[String]')
    expect(typeset).to be_rooted
  end

  it 'resolves relative paths' do
    source = Solargraph::Source.load_string(%(
      module Example
        class String; end
      end
    ), 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    link = Solargraph::Source::Chain::Constant.new('String')
    dictionary = double(Solargraph::Typedef::Dictionary, api_map: api_map)
    constant = Solargraph::Typedef::Linker::Constant.new(dictionary, link, api_map.get_path_pins('Example').first)
    result = constant.resolve.first
    typeset = result.typedef_typeset
    expect(typeset.to_s).to eq('Class[Example::String]')
    expect(typeset).to be_rooted
  end
end
