describe Solargraph::Plugin::Runtime do
  it "finds runtime methods" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    result = runtime.get_methods(namespace: 'File', root: '', scope: 'class')
    expect(result).to include('exist?')
  end
end
