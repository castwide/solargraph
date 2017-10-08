describe Solargraph::ApiMap::Source do
  it "finds require calls" do
    code = %(
      require 'solargraph'
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required).to include('solargraph')
  end
  it "ignores dynamic require calls" do
    code = %(
      path = 'solargraph'
      require path
    )
    source = Solargraph::ApiMap::Source.virtual('file.rb', code)
    expect(source.required.length).to eq(0)
  end
end
