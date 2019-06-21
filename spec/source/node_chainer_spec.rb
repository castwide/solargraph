describe Solargraph::Source::NodeChainer do
  it "recognizes self keywords" do
    chain = Solargraph::Source::NodeChainer.load_string('self.foo')
    expect(chain.links.first.word).to eq('self')
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Head)
  end

  it "recognizes super keywords" do
    chain = Solargraph::Source::NodeChainer.load_string('super.foo')
    expect(chain.links.first.word).to eq('super')
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Head)
  end

  it "recognizes constants" do
    chain = Solargraph::Source::NodeChainer.load_string('Foo::Bar')
    expect(chain.links.length).to eq(1)
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::Constant)
    expect(chain.links.map(&:word)).to eq(['Foo::Bar'])
  end

  it "splits method calls with arguments and blocks" do
    chain = Solargraph::Source::NodeChainer.load_string('var.meth1(1, 2).meth2 do; end')
    expect(chain.links.map(&:word)).to eq(['var', 'meth1', 'meth2'])
  end

  it "recognizes literals" do
    chain = Solargraph::Source::NodeChainer.load_string('"string"')
    expect(chain).to be_literal
    chain = Solargraph::Source::NodeChainer.load_string('100')
    expect(chain).to be_literal
    chain = Solargraph::Source::NodeChainer.load_string('[1, 2, 3]')
    expect(chain).to be_literal
    chain = Solargraph::Source::NodeChainer.load_string('{ foo: "bar" }')
    expect(chain).to be_literal
  end

  it "recognizes instance variables" do
    chain = Solargraph::Source::NodeChainer.load_string('@foo')
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::InstanceVariable)
  end

  it "recognizes class variables" do
    chain = Solargraph::Source::NodeChainer.load_string('@@foo')
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::ClassVariable)
  end

  it "recognizes global variables" do
    chain = Solargraph::Source::NodeChainer.load_string('$foo')
    expect(chain.links.first).to be_a(Solargraph::Source::Chain::GlobalVariable)
  end

  it "operates on nodes" do
    source = Solargraph::Source.load_string(%(
      class Foo
        Bar.meth1(1, 2).meth2{}
      end
    ))
    node = source.node_at(2, 25)
    chain = Solargraph::Source::NodeChainer.chain(node)
    expect(chain.links.map(&:word)).to eq(['Bar', 'meth1', 'meth2'])
  end

  it 'chains and/or nodes' do
    source = Solargraph::Source.load_string(%(
      [] || ''
    ))
    chain = Solargraph::Source::NodeChainer.chain(source.node)
    expect(chain).to be_defined
  end
end
