# frozen_string_literal: true

describe Solargraph::Diagnostics::Base do
  it 'returns empty diagnostics' do
    reporter = described_class.new
    expect(reporter.diagnose(nil, nil)).to be_empty
  end
end
