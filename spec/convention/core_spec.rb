describe Solargraph::Convention::Core do
  it 'maps core Errno classes' do
    api_map = Solargraph::ApiMap.new
    core = Solargraph::Convention::Core.new
    environ = core.global(api_map)
    store = Solargraph::ApiMap::Store.new(environ.pins)
    Errno.constants.each do |const|
      pin = store.get_path_pins("Errno::#{const}").first
      expect(pin).to be_a(Solargraph::Pin::Namespace)
      superclass = store.get_superclass(pin.path)
      expect(superclass).to eq('SystemCallError')
    end
  end
end
