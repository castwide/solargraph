describe "EOL handling" do
  it "finds the same node with different EOLs" do
    code = "\nclass Butt\ndef lol;end\nend\n\n\n\n\n\n\nbuddy what the fuck this is ridiculous\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nnow is the time fore all good men to come to the aid of the country\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nclass Foo\n  def bar\n    {\n    }\n    a\n  end\nend\n"

    source_lf = Solargraph::Source.load_string(code)
    frag_lf = source_lf.fragment_at(62, 5)

    source_crlf = Solargraph::Source.load_string(code.gsub(/\n/, "\r\n"))
    frag_crlf = source_crlf.fragment_at(62, 5)

    expect(frag_lf.node.to_s).to eq(frag_crlf.node.to_s)
  end
end
