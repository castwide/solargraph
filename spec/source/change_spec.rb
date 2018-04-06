describe Solargraph::Source::Change do
  it "inserts a character" do
    text = 'var'
    range = Solargraph::Source::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    change = Solargraph::Source::Change.new(range, new_text)
    updated = change.write(text)
    expect(updated).to eq('var.')
  end

  it "repairs nullable characters" do
    text = 'var'
    range = Solargraph::Source::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    change = Solargraph::Source::Change.new(range, new_text)
    updated = change.write(text, true)
    expect(updated).to eq('var ')
  end
end
