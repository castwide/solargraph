# frozen_string_literal: true

describe Solargraph::Typedef::Token do
  it 'does not resolve unreserved names' do
    token = described_class.new('test')
    expect(token).not_to be_resolved
  end

  it 'resolves undefined' do
    token = described_class.new('undefined')
    expect(token).to be_resolved
  end

  it 'resolves nil' do
    token = described_class.new('nil')
    expect(token).to be_resolved
  end
end
