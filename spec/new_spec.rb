describe "Fragment base_type" do
  before :all do
    @api_map = Solargraph::ApiMap.new
  end

  it "infers methods from blanks" do
    source = Solargraph::Source.load_string(%(
      class Foo
      end
    ))
    @api_map.virtualize source
    fragment = source.fragment_at(3, 0)
    pins = @api_map.complete(fragment).pins.map(&:path)
    expect(pins).to include('Kernel#puts')
  end

  it "uses a fragment to resolve a variable" do
    source = Solargraph::Source.load_string(%(
      class Foo
        # @return [String]
        def bar
        end
      end
      foo = Foo.new.bar
      foo
    ))
    @api_map.virtualize source
    lvar = source.local_variable_pins.first
    lvar.resolve @api_map
    expect(lvar.return_type).to eq('String')
  end
end
