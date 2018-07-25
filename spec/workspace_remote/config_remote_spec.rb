describe Solargraph::WorkspaceRemote::ConfigRemote do

  before(:each) {
    @config = Solargraph::WorkspaceRemote::ConfigRemote.new nil, [
      "file:///foo.rb",
      "file:///foo/bar.rb",
      "file:///spec/foo_spec.rb",
      "file:///spec/foo/bar_spec.rb",
      "file:///.bundle/foo.rb",
    ]
  }

  describe "initialize" do
    it "should apply include and exclude globs to files" do
      expect(@config.calculated).to eq [
        "file:///foo.rb",
        "file:///foo/bar.rb",
      ]
    end
  end

  describe "included" do
    it "should include files that match globs" do
      expect(@config.included).to eq [
        "file:///foo.rb",
        "file:///foo/bar.rb",
        "file:///spec/foo_spec.rb",
        "file:///spec/foo/bar_spec.rb",
      ]
    end
  end

  describe "excluded" do
    it "should exclude files that match globs" do
      expect(@config.excluded).to eq [
        "file:///spec/foo_spec.rb",
        "file:///spec/foo/bar_spec.rb",
        "file:///.bundle/foo.rb",
      ]
    end
  end

end