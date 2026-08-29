# frozen_string_literal: true

describe Solargraph::Typedef::Memos do
  let(:key) { Solargraph::Typedef::Memos::Key.new(filename: 'example.rb', api_map: nil, position: nil, chain: nil, action: :example) }
  let(:key2) { Solargraph::Typedef::Memos::Key.new(filename: 'other.rb', api_map: nil, position: nil, chain: nil, action: :example) }
  let(:memos) { described_class.new }

  it 'saves on fetch' do
    memos.fetch(key) { 'value' }
    expect(memos.cache[key].value).to eq('value')
  end

  it 'fetches memoized values' do
    memos.cache[key] = Solargraph::Typedef::Memo.new('value', [])
    result = memos.fetch(key) { raise 'Should not happen' }
    expect(result).to eq('value')
  end

  it 'clears the cache' do
    memos.cache[key] = Solargraph::Typedef::Memo.new('value', [])
    memos.clear
    expect(memos.cache).to be_empty
  end

  it 'tracks pending memos' do
    memos.cache[key] do
      expect(memos.pending).to include(key)
    end
    expect(memos.pending).not_to include(key)
  end

  it 'returns default on recursive actions' do
      result = memos.fetch(key) do
        memos.fetch(key, 'safe') { 'oops' }
      end
      expect(result).to be('safe')
  end

  it 'returns cache for equivalent keys' do
    key2 = key.clone
    memos.fetch(key) { 'one' }
    result = memos.fetch(key2) { 'two' }
    expect(result).to eq('one')
    expect(memos.cache).to be_one
  end

  it 'filters cache by filename' do
    memos.fetch(key) { 'first' }
    memos.fetch(key2) { 'second' }
    expect(memos.cache.length).to be(2)

    memos.filter('other.rb')
    expect(memos.cache).to be_one
    expect(memos.cache[key].value).to eq('first')
  end

  it 'cascades values' do
    result = memos.fetch(key) do
      memos.fetch(key2) { 'value' }
    end
    expect(result).to eq('value')
  end

  it 'stacks memo filenames' do
    memos.fetch(key) do
      memos.fetch(key2) { 'value' }
    end
    expect(memos.cache[key].stack).to match_array(['example.rb'])
    expect(memos.cache[key2].stack).to match_array(['example.rb', 'other.rb'])
  end
end
