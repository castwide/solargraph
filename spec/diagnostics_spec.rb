describe Solargraph::Diagnostics do
  it "registers reporters" do
    Solargraph::Diagnostics.register 'base', Solargraph::Diagnostics::Base
    expect(Solargraph::Diagnostics.reporters).to include('base')
    expect(Solargraph::Diagnostics.reporter('base')).to be(Solargraph::Diagnostics::Base)
  end
end
