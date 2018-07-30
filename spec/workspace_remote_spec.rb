describe Solargraph::WorkspaceRemote do

  before(:each) {
    @host = instance_double Solargraph::LanguageServer::Host
    allow(@host).to receive(:send_request)
    allow(@host).to receive(:initialized)
    @library = instance_double Solargraph::LibraryRemote
  }

  describe "initalize" do
    describe "without directory" do
      it "should not load files" do
        workspace = Solargraph::WorkspaceRemote.new @host, @library
        expect(@host).to_not have_received(:send_request)
      end
    end

    describe "with directory" do
      it "should load files" do
        workspace = Solargraph::WorkspaceRemote.new @host, @library, ["/foo"]
        expect(@host).to have_received(:send_request).with("workspace/xfiles", {"base"=>"file://[\"/foo\"]"})
      end
    end
  end

  describe "config" do
    before(:each) {
      @workspace = Solargraph::WorkspaceRemote.new @host, @library, ["/foo"]
    }

    describe "with no files and no config" do
      it "should create config" do
        config = @workspace.config
        expect(config).to be_kind_of(Solargraph::WorkspaceRemote::ConfigRemote)
      end
    end

    describe "with config and no files" do
      it "should return existing config" do
        config = @workspace.config
        config_new = @workspace.config
        expect(config).to equal(config_new)
      end
    end

    describe "with config and files" do
      it "should return new config" do
        config = @workspace.config
        config_new = @workspace.config ["/bar"]
        expect(config).to_not equal(config_new)
      end
    end
  end

  describe "load_file_list" do
    before(:each) {
      @workspace = Solargraph::WorkspaceRemote.new @host, @library
    }

    it "should load files" do
      @workspace.load_file_list
      expect(@host).to have_received(:send_request).with("workspace/xfiles", {"base"=>"file://"})
    end
  end

  describe "load_sources" do
    before(:each) {
      @workspace = Solargraph::WorkspaceRemote.new @host, @library, ["/foo"]
    }

    describe "without files" do
      it "should set host initialized" do
        @workspace.load_sources
        expect(@host).to have_received(:initialized).with(true)
      end
    end

    describe "with files" do

      before(:each) {
        @workspace.config ["/foo.rb", "/bar.rb"]
      }

      it "should request files" do
        @workspace.load_sources
        expect(@host).to have_received(:send_request).with("textDocument/xcontent", {'textDocument' => {'uri' => "/foo.rb"}})
        expect(@host).to have_received(:send_request).with("textDocument/xcontent", {'textDocument' => {'uri' => "/bar.rb"}})
      end
    end
  end
end
