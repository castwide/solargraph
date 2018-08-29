describe Solargraph::Source::CallChainer do
  it "handles trailing colons that are not namespace separators" do
    source = Solargraph::Source.load_string('Foo:')
    fragment = source.fragment_at(0, 4)
    expect(fragment.chain.links.first).to be_undefined
  end
end
