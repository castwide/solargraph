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

  it 'understands RBS class aliases' do
    map = Solargraph::RbsMap::CoreMap.new
    store = Solargraph::ApiMap::Store.new(map.pins)
    # The core RBS contains:
    #   class Mutex = Thread::Mutex
    thread_mutex_pin = store.get_path_pins("Thread::Mutex").first
    expect(thread_mutex_pin).to be_a(Solargraph::Pin::Namespace)

    mutex_pin = store.get_path_pins("Mutex").first
    expect(mutex_pin).to be_a(Solargraph::Pin::Constant)
    expect(mutex_pin.return_type.to_s).to eq("Class<Thread::Mutex>")
  end
end
