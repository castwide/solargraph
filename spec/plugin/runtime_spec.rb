describe Solargraph::Plugin::Runtime do
  it "finds runtime methods" do
    runtime = Solargraph::Plugin::Runtime.new(nil)
    runtime.start
    retries = 10
    got_ok = false
    while retries > 0
      result = runtime.get_methods(namespace: 'File', root: '', scope: 'class')
      if result.ok?
        got_ok = true
        expect(result.data).to include('exist?')
        break
      else
        STDERR.puts "Waiting for runtime server..."
        retries -= 1
        sleep(1)
      end
    end
    expect(got_ok).to eq(true)
  end
end
