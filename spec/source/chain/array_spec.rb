# frozen_string_literal: true

describe Solargraph::Source::Chain::Array do
  # @param code [String]
  # @return [String]
  def infer_last_line code
    source = Solargraph::Source.load_string(code, 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    clip = api_map.clip_at('test.rb', [code.lines.length - 1, 0])
    clip.infer.to_s
  end

  it 'resolves an instance of an array' do
    literal = described_class.new([], nil)
    pin = literal.resolve(nil, nil, nil).first
    expect(pin.return_type.tag).to eq('Array')
  end

  it 'infers the element type of a homogeneous literal' do
    expect(infer_last_line("a = [1, 2, 3]\na")).to eq('Array<Integer>')
  end

  it 'infers a union element type, not a tuple, for a heterogeneous literal' do
    expect(infer_last_line("a = [1, 'a', 2]\na")).to eq('Array<Integer, String>')
  end

  it 'includes nil in the element type, as a declared Array<Integer, nil> does' do
    declared = infer_last_line("# @return [Array<Integer, nil>]\ndef m; end\na = m\na")
    expect(infer_last_line("a = [1, nil]\na")).to eq(declared)
  end

  it 'merges repeated element types that hold undefined' do
    expect(infer_last_line("# @return [Hash{Symbol => undefined}]\ndef m; end\nx = m\na = [x, x]\na"))
      .to eq('Array<Hash{Symbol => undefined}>')
  end

  it 'infers element types of nested literals' do
    expect(infer_last_line("a = [[1], ['a']]\na")).to eq('Array<Array<Integer>, Array<String>>')
  end

  it 'leaves an empty literal as a bare Array' do
    expect(infer_last_line("a = []\na")).to eq('Array')
  end

  it 'leaves a literal with a splat as a bare Array' do
    expect(infer_last_line("a = [1, *[2]]\na")).to eq('Array')
  end

  it 'leaves a literal with an element of unknown type as a bare Array' do
    expect(infer_last_line("a = [1, unknown_method]\na")).to eq('Array')
  end

  it 'leaves a literal with a self element as a bare Array, not the defining class' do
    code = "class Foo\n  def all\n    [self]\n  end\nend\nclass Sub < Foo; end\na = Sub.new.all\na"
    expect(infer_last_line(code)).to eq('Array')
  end

  it 'leaves a literal with a void element as a bare Array' do
    expect(infer_last_line("# @return [void]\ndef m; end\na = [m]\na")).to eq('Array')
  end

  it 'distinguishes literals with different elements when inferring a chain base' do
    source = Solargraph::Source.load_string("[1].first\n['a'].first\n", 'test.rb')
    api_map = Solargraph::ApiMap.new.map(source)
    ints = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(0, 6))
    strings = Solargraph::Source::SourceChainer.chain(source, Solargraph::Position.new(1, 8))
    ints.base.infer(api_map, Solargraph::Pin::ROOT_PIN, [])
    expect(strings.base.infer(api_map, Solargraph::Pin::ROOT_PIN, []).to_s).to eq('Array<String>')
  end

  it 'does not track mutation after assignment' do
    # The literal's type is inferred from its elements; the later push
    # does not widen it.
    expect(infer_last_line("y = [1]\ny.push 'two'\ny")).to eq('Array<Integer>')
  end
end
