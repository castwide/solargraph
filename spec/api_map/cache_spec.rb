describe Solargraph::ApiMap::Cache do
  it "recognizes empty caches" do
    cache = Solargraph::ApiMap::Cache.new
    expect(cache).to be_empty
    cache.set_methods('', :class, [:public], true, [])
    expect(cache).not_to be_empty
  end
end
