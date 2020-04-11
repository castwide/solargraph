describe Solargraph::Pin::BaseMethod do
  it 'typifies from super methods' do
    source = Solargraph::Source.load_string(%(
      class Sup
        # @return [String]
        def foobar; end
      end
      class Sub < Sup
        def foobar; end
      end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Sub#foobar').first
    type = pin.typify(api_map)
    expect(type.tag).to eq('String')
  end

  it 'assumes interrogative methods are Boolean' do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar?; end
      end
    ))
    api_map = Solargraph::ApiMap.new
    api_map.map source
    pin = api_map.get_path_pins('Foo#bar?').first
    # The return type is undefined without a @return tag
    expect(pin.return_type).to be_undefined
    # Typify infers Boolean
    type = pin.typify(api_map)
    expect(type.tag).to eq('Boolean')
  end

  it 'supports multiple return tags' do
    pin = Solargraph::Pin::BaseMethod.new(
      name: 'foo',
      comments: %(
@return [String]
@return [Integer]
      )
    )
    expect(pin.return_type.to_s).to eq('String, Integer')
  end

  it 'includes @return text in documentation' do
    pin = Solargraph::Pin::BaseMethod.new(
      name: 'foo',
      comments: %(
@return [String] the foo text string
      )
    )
    expect(pin.documentation).to include('the foo text string')
  end
end
