describe Solargraph::ApiMap::Source do
  it "finds require calls" do
    code = %(
      require 'solargraph'
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required).to include('solargraph')
  end

  it "ignores dynamic require calls" do
    code = %(
      path = 'solargraph'
      require path
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required.length).to eq(0)
  end

  it "finds attributes in YARD directives" do
    code = %(
      class Foo
        # @!attribute [r] bar
        #   @return [String]
      end
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.attribute_pins.length).to eq(1)
    expect(source.attribute_pins[0].name).to eq('bar')
    expect(source.attribute_pins[0].return_type).to eq('String')
  end

  it "finds methods in YARD directives" do
    code = %(
      class Foo
        # @!method bar
        #   @return [String]
      end
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.method_pins.length).to eq(1)
    expect(source.method_pins[0].name).to eq('bar')
    expect(source.method_pins[0].return_type).to eq('String')
  end

  it "pins global variables" do
    code = %(
      $foo = 'foo'
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.global_variable_pins.length).to eq(1)
    expect(source.global_variable_pins[0].name).to eq('$foo')
  end
end
