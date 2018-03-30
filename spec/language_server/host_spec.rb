require 'tmpdir'

describe Solargraph::LanguageServer::Host do
  it "prepares a workspace" do
    host = Solargraph::LanguageServer::Host.new
    Dir.mktmpdir do |dir|
      host.prepare (dir)
      expect(host.library).not_to be(nil)
    end
  end
end
