describe Solargraph::Source::Cursor do
  it "detects cursors in strings" do
    source = Solargraph::Source.load_string('str = "string"')
    cursor = described_class.new(source, Solargraph::Position.new(0, 6))
    expect(cursor).not_to be_string
    cursor = described_class.new(source, Solargraph::Position.new(0, 7))
    expect(cursor).to be_string
  end

  it "detects cursors in comments" do
    source = Solargraph::Source.load_string(%(
      # @type [String]
      var = make_a_string
    ))
    cursor = described_class.new(source, Solargraph::Position.new(1, 6))
    expect(cursor).not_to be_comment
    cursor = described_class.new(source, Solargraph::Position.new(1, 7))
    expect(cursor).to be_comment
    cursor = described_class.new(source, Solargraph::Position.new(2, 0))
    expect(cursor).not_to be_comment
  end

  it "detects arguments" do
    source = double(:Source, :code => 'a(1), b')
    cur = described_class.new(source, Solargraph::Position.new(0,2))
    expect(cur).to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,3))
    expect(cur).to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,4))
    expect(cur).not_to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,5))
    expect(cur).not_to be_argument
    cur = described_class.new(source, Solargraph::Position.new(0,7))
    expect(cur).not_to be_argument
  end
end
