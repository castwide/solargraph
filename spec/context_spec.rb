describe Solargraph::Context do
  it "returns a namespace and an instance scope" do
    context = described_class.new('Foo', :instance)
    expect(context.namespace).to eq('Foo')
    expect(context.scope).to eq(:instance)
  end

  it "returns a namespace and a class scope" do
    context = described_class.new('Foo', :class)
    expect(context.namespace).to eq('Foo')
    expect(context.scope).to eq(:class)
  end

  it "raises an InvalidScopeError" do
    expect {
      described_class.new('Foo', :bad_scope)
    }.to raise_error(ArgumentError)
  end

  it "recognizes equivalent contexts" do
    c1 = described_class.new('Foo', :class)
    c2 = described_class.new('Foo', :class)
    expect(c1).to eq(c2)
  end

  it "recognizes inequivalent namespaces" do
    c1 = described_class.new('Foo', :class)
    c2 = described_class.new('Bar', :class)
    expect(c1).not_to eq(c2)
  end

  it "recognizes inequivalent scopes" do
    c1 = described_class.new('Foo', :class)
    c2 = described_class.new('Foo', :instance)
    expect(c1).not_to eq(c2)
  end
end
