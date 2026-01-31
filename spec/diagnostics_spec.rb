# frozen_string_literal: true

describe Solargraph::Diagnostics do
  it 'registers reporters' do
    described_class.register 'base', Solargraph::Diagnostics::Base
    expect(described_class.reporters).to include('base')
    expect(described_class.reporter('base')).to be(Solargraph::Diagnostics::Base)
  end
end
