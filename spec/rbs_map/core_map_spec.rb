describe Solargraph::RbsMap::CoreMap do
  it 'maps core Errno classes' do
    map = Solargraph::RbsMap::CoreMap.new
    store = Solargraph::ApiMap::Store.new(map.pins)
    Errno.constants.each do |const|
      pin = store.get_path_pins("Errno::#{const}").first
      expect(pin).to be_a(Solargraph::Pin::Namespace)
      superclass = store.get_superclass(pin.path)
      expect(superclass).to eq('SystemCallError')
    end
  end
end
