describe Solargraph::Pin::Documenting do
  let(:object) {
    Class.new do
      include Solargraph::Pin::Documenting
      attr_accessor :docstring
    end.new
  }

  it 'parses indented code blocks' do
    object.docstring = YARD::Docstring.new(%(Method overview

Example code:

  class Foo; end
))
    expect(object.documentation).to include("```ruby\nclass Foo; end\n```")
  end

  it 'allows unclosed tags' do
    object.docstring = YARD::Docstring.new('comment <tt>code')
    expect(object.documentation).to include('comment `code`')
  end
end
