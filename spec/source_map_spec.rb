describe Solargraph::SourceMap do
  it "locates named path pins" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        def bar; end
      end
    ))
    pin = map.locate_named_path_pin(2, 16)
    expect(pin.path).to eq('Foo#bar')
  end

  it "locates block pins" do
    map = Solargraph::SourceMap.load_string(%(
      class Foo
        100.times do
        end
      end
    ))
    pin = map.locate_block_pin(3, 0)
    expect(pin.kind).to eq(Solargraph::Pin::BLOCK)
  end
end
