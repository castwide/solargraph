# frozen_string_literal: true

describe Solargraph::Typedef::Memoizer::Cache do
  let(:key) { Solargraph::Typedef::Memoizer::Key.new(filename: 'example1.rb', api_map: nil, position: nil, chain: nil, action: :example) }
  let(:key2) { Solargraph::Typedef::Memoizer::Key.new(filename: 'example2.rb', api_map: nil, position: nil, chain: nil, action: :example) }
  let(:key3) { Solargraph::Typedef::Memoizer::Key.new(filename: 'example3.rb', api_map: nil, position: nil, chain: nil, action: :example) }
  let(:memos) { described_class.new }

  it 'saves on fetch' do
    memos.fetch(key, 'value')
    expect(memos.data[key].value).to eq('value')
  end

  it 'fetches memoized values' do
    memos.data[key] = Solargraph::Typedef::Memoizer::Memo.new('value', [])
    result = memos.fetch(key) { raise 'Should not happen' }
    expect(result).to eq('value')
  end

  it 'clears the cache' do
    memos.data[key] = Solargraph::Typedef::Memoizer::Memo.new('value', [])
    memos.clear
    expect(memos.data).to be_empty
  end

  it 'tracks pending memos' do
    memos.data[key] do
      expect(memos.pending).to include(key)
    end
    expect(memos.pending).not_to include(key)
  end

  it 'returns default on recursive actions' do
    result = memos.fetch(key) do
      memos.fetch(key, 'oops')
    end
    expect(result).to be('oops')
  end

  it 'returns cache for equivalent keys' do
    key2 = key.clone
    memos.fetch(key, 'one')
    result = memos.fetch(key2, 'two')
    expect(result).to eq('one')
    expect(memos.data).to be_one
  end

  it 'filters cache by filename' do
    memos.fetch(key, 'first')
    memos.fetch(key2, 'second')
    expect(memos.data.length).to be(2)

    memos.filter('example2.rb')
    expect(memos.data).to be_one
    expect(memos.data[key].value).to eq('first')
  end

  it 'cascades values' do
    result = memos.fetch(key) do
      memos.fetch(key2, 'value')
    end
    expect(result).to eq('value')
  end

  it 'stacks memo filenames' do
    memos.fetch(key) do
      memos.fetch(key2) do
        memos.fetch(key3)
      end
    end
    expect(memos.data[key].stack).to contain_exactly('example1.rb', 'example2.rb', 'example3.rb')
    expect(memos.data[key2].stack).to contain_exactly('example2.rb', 'example3.rb')
    expect(memos.data[key3].stack).to contain_exactly('example3.rb')
  end
end
