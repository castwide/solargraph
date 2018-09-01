describe Solargraph::Source::Updater do
  it "applies changes" do
    text = 'foo'
    changes = []
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    changes.push Solargraph::Source::Change.new(range, new_text)
    range = Solargraph::Range.from_to(0, 4, 0, 4)
    new_text = 'bar'
    changes.push Solargraph::Source::Change.new(range, new_text)
    updater = Solargraph::Source::Updater.new('file.rb', 0, changes)
    updated = updater.write(text)
    expect(updated).to eq('foo.bar')
  end

  it "applies repairs" do
    text = 'foo'
    changes = []
    range = Solargraph::Range.from_to(0, 3, 0, 3)
    new_text = '.'
    changes.push Solargraph::Source::Change.new(range, new_text)
    range = Solargraph::Range.from_to(0, 4, 0, 4)
    new_text = 'bar'
    changes.push Solargraph::Source::Change.new(range, new_text)
    updater = Solargraph::Source::Updater.new('file.rb', 0, changes)
    updated = updater.repair(text)
    expect(updated).to eq('foo    ')
  end
end
