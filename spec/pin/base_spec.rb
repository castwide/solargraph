describe Solargraph::Pin::Base do
  it "returns its location in the source" do
    source = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end
    ), 'file.rb')
    source.namespace_pins.each do |pin|
      expect(pin.location).not_to be_nil
    end
    source.method_pins.each do |pin|
      expect(pin.location).not_to be_nil
    end
  end
end
