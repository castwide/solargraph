# frozen_string_literal: true

describe Solargraph::Typedef::Memos do
  let(:memos) { described_class.new }

  it 'saves on fetch' do
    memos.fetch('key') { 'value' }
    expect(memos.cache['key']).to eq('value')
  end

  it 'fetches memoized values' do
    memos.cache['key'] = 'value'
    result = memos.fetch('key') { raise 'Should not happen' }
    expect(result).to eq('value')
  end

  it 'clears the cache' do
    memos.cache['key'] = 'value'
    memos.clear
    expect(memos.cache).to be_empty
  end

  it 'tracks pending memos' do
    memos.cache['key'] do
      expect(memos.pending).to include('key')
    end
    expect(memos.pending).not_to include('key')
  end

  it 'raises errors on recursive actions' do
    expect {
      memos.fetch('key') do
        memos.fetch('key') { 'oops' }
      end
    }.to raise_error
  end
end
