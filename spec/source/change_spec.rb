# frozen_string_literal: true

describe Solargraph::Source::Change do
  it 'inserts a character' do
    text = 'var'
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    change = described_class.new(range, new_text)
    updated = change.write(text)
    expect(updated).to eq('var.')
  end

  it 'repairs nullable characters' do
    text = 'var'
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    change = described_class.new(range, new_text)
    updated = change.write(text, true)
    expect(updated).to eq('var ')
  end

  it 'repairs entire changes' do
    text = 'var'
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    new_text = '._(!'
    change = described_class.new(range, new_text)
    updated = change.repair(text)
    expect(updated).to eq('var    ')
  end

  it 'repairs nil ranges' do
    text = 'original'
    change = described_class.new(nil, '...')
    updated = change.repair(text)
    expect(updated).to eq('   ')
  end

  it 'overwrites nil ranges' do
    text = 'foo'
    new_text = 'bar'
    change = described_class.new(nil, new_text)
    updated = change.write(text)
    expect(updated).to eq('bar')
  end

  it 'blanks single colons in nullable changes' do
    text = 'bar'
    new_text = ':'
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    change = described_class.new(range, new_text)
    updated = change.write(text, true)
    expect(updated).to eq('bar ')
  end

  it 'blanks double colons in nullable changes' do
    text = 'bar:'
    new_text = ':'
    range = Solargraph::Range.from_to(0, 4, 0, 4)
    change = described_class.new(range, new_text)
    updated = change.write(text, true)
    expect(updated).to eq('bar  ')
  end

  it 'repairs preceding periods' do
    text = 'bar.'
    new_text = ' '
    range = Solargraph::Range.from_to(0, 4, 0, 4)
    change = described_class.new(range, new_text)
    updated = change.repair(text)
    expect(updated).to eq('bar  ')
  end

  it 'repairs preceding colons' do
    text = 'bar:'
    new_text = 'x'
    range = Solargraph::Range.from_to(0, 4, 0, 4)
    change = described_class.new(range, new_text)
    updated = change.repair(text)
    expect(updated).to eq('bar  ')
  end
end
