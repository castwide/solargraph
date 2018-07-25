describe Solargraph::SourceRemote do

  describe "load" do
    it "should raise error" do
      expect { Solargraph::SourceRemote.load "foo" }.to raise_error(NoMethodError)
    end
  end

  describe "load_string" do
    it "should return new instance" do
      source = Solargraph::SourceRemote.load_string "foo", "bar"
      expect(source).to be_kind_of(Solargraph::SourceRemote)
    end
  end

end