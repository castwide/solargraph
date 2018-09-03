require 'tmpdir'

# @todo Runtime is pending
describe Solargraph::Plugin::Runtime do
  # it "finds runtime methods" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_methods(namespace: 'File', root: '', scope: 'class').map{|m| m['name']}
  #   expect(result).to include('exist?')
  # end

  # it "finds top-level constants" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_constants('', '').map{ |o| o['name']}
  #   expect(result).to include('String')
  #   expect(result).to include('Array')
  # end

  # it "ignores the Solargraph namespace by default" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_constants('', '').map{ |o| o['name'] }
  #   expect(result).not_to include('Solargraph')
  # end

  # it "finds namespaces required from stdlib" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   # @todo Should send_require be exposed?
  #   runtime.send(:send_require, ['json'])
  #   result = runtime.get_constants('', '').map{ |o| o['name'] }
  #   expect(result).to include('JSON')
  # end

  # it "finds fully qualified namespaces" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_fqns('String', 'Foo')
  #   expect(result).to eq('String')
  #   result = runtime.get_fqns('Constants', 'File')
  #   expect(result).to eq('File::Constants')
  # end

  # it "does not need a refresh without ApiMap changes" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   expect(runtime.refresh).to eq(false)
  # end

  # it "returns internal namespace names" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_constants('Process', '').map{ |o| o['name'] }
  #   # Process::Tms is known to exist at runtime but not in documentation in
  #   # Ruby 2.3.3 et al.
  #   expect(result).to include('Tms')
  # end

  # it "sets local name and namespace root for constants" do
  #   runtime = Solargraph::Plugin::Runtime.new(nil)
  #   result = runtime.get_constants('Process', '').select{|o| o['name'] == 'Tms'}.first
  #   expect(result).not_to be(nil)
  #   expect(result['name']).to eq('Tms')
  #   expect(result['namespace']).to eq('Process')
  # end

  # it "uses the workspace directory" do
  #   Dir.mktmpdir do |dir|
  #     api_map = Solargraph::ApiMap.load(dir)
  #     runtime = Solargraph::Plugin::Runtime.new(api_map)
  #     result = runtime.get_methods(namespace: 'File', root: '', scope: :class).map{|r| r['name']}
  #     expect(result).to include('exist?')
  #     runtime.stop
  #   end
  # end
end
