describe Solargraph::Plugin::Runtime do
  it "finds runtime methods" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_methods(namespace: 'File', root: '', scope: 'class').map{|m| m['name']}
    expect(result).to include('exist?')
  end

  it "finds top-level constants" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_constants('', '').map{ |o| o['name']}
    expect(result).to include('String')
    expect(result).to include('Array')
  end

  it "ignores the Solargraph namespace by default" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_constants('', '').map{ |o| o['name'] }
    expect(result).not_to include('Solargraph')
  end

  # @todo Make the process ignore namespaces that were included from Solargraph
  #it "does not include stdlib namespaces that were not required" do
  #  runtime = Solargraph::Plugin::Runtime.new(nil)
  #  result = runtime.get_constants('', '').map{ |o| o['name'] }
  #  expect(result).not_to include('JSON')
  #end

  it "finds namespaces required from stdlib" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    # @todo Should send_require be exposed?
    runtime.send(:send_require, ['json'])
    result = runtime.get_constants('', '').map{ |o| o['name'] }
    expect(result).to include('JSON')
  end

  it "finds fully qualified namespaces" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_fqns('String', 'Foo')
    expect(result).to eq('String')
    result = runtime.get_fqns('Constants', 'File')
    expect(result).to eq('File::Constants')
  end

  it "does not need a refresh without ApiMap changes" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    expect(runtime.refresh).to eq(false)
  end

  it "returns internal namespace names" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_constants('Process', '').map{ |o| o['name'] }
    expect(result).to include('Waiter')
  end

  it "sets local name and namespace root for constants" do
    tmp = Class.new(Solargraph::Plugin::Runtime) do
      define_method :executable do
        'bundle exec solargraph-runtime'
      end
    end
    runtime = tmp.new(nil)
    result = runtime.get_constants('Process', '').select{|o| o['name'] == 'Waiter'}.first
    expect(result).not_to be(nil)
    expect(result['name']).to eq('Waiter')
    expect(result['namespace']).to eq('Process')
  end
end
