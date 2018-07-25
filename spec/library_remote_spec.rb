describe Solargraph::LibraryRemote do

  before(:each) {
    @host = instance_double Solargraph::LanguageServer::Host
    allow(@host).to receive(:send_request)
    allow(@host).to receive(:initialized)
  }

  describe "api_map" do
    before(:each) {
      @library = Solargraph::LibraryRemote.load @host, "/foo"
    }

    describe "when api map not set" do
      it "should set host initialized" do
        @library.api_map
        expect(@host).to have_received(:initialized).with(true)
      end
    end

    describe "when api map set" do
      it "should return api map" do
        api_map = @library.api_map
        api_map_new = @library.api_map
        expect(api_map).to equal(api_map_new)
      end
    end
  end

  describe "load" do
    before(:each) {
      allow(Solargraph::LibraryRemote).to receive(:new).and_return Solargraph::LibraryRemote.new @host
      allow(Solargraph::LibraryRemote).to receive(:api_map)
      Solargraph::LibraryRemote.load @host, "/foo"
    }

    it "should create new instance" do
      expect(Solargraph::LibraryRemote).to have_received(:new)
    end

    it "should not call api_map" do
      expect(Solargraph::LibraryRemote).to_not have_received(:api_map)
    end
  end

  describe "workspace" do
    before(:each) {
      @library = Solargraph::LibraryRemote.load @host, "/foo"
    }

    describe "when no workspace passed" do
      it "should return workspace" do
        expect(@library.workspace).to be_kind_of(Solargraph::WorkspaceRemote)
      end
    end

    describe "when workspace passed" do
      it "should set workspace" do
        set_workspace = instance_double Solargraph::WorkspaceRemote
        new_workspace = @library.workspace set_workspace
        expect(new_workspace).to equal(set_workspace)
        expect(@library.workspace).to equal(set_workspace)
      end
    end
  end

end