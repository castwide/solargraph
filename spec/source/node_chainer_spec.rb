describe Solargraph::Source::NodeChainer do
  it "recognizes self keywords" do
    chain = Solargraph::Source::NodeChainer.load_string('self.foo')
    expect(chain.links.first.word).to eq('self')
  end

  it "recognizes constants" do
    chain = Solargraph::Source::NodeChainer.load_string('Foo::Bar')
    expect(chain.links.length).to eq(1)
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Constant)
    expect(chain.links.first.word).to eq('Foo::Bar')
  end

  it "splits method calls with arguments and blocks" do
    chain = Solargraph::Source::NodeChainer.load_string('var.meth1(1, 2).meth2 do; end')
    expect(chain.links.map(&:word)).to eq(['var', 'meth1', 'meth2'])
  end
end
