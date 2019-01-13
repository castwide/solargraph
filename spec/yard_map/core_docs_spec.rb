require 'fileutils'
require 'tmpdir'

describe Solargraph::YardMap::CoreDocs do
  before :all do
    # Override the cache for testing
    @tmp_dir = Dir.mktmpdir
    @orig_env = ENV['SOLARGRAPH_CACHE']
    ENV['SOLARGRAPH_CACHE'] = @tmp_dir
  end

  after :all do
    # Delete the temp cache and reset
    FileUtils.rm_rf @tmp_dir, secure: true
    ENV['SOLARGRAPH_CACHE'] = @orig_env
  end

  it "detects nil available matches" do
    expect(Solargraph::YardMap::CoreDocs.best_match).to be_nil
  end

  it "sets the minimum requirements" do
    expect {
      Solargraph::YardMap::CoreDocs.require_minimum
    }.not_to raise_error
    expect(Solargraph::YardMap::CoreDocs.best_match).to eq(Solargraph::YardMap::CoreDocs::DEFAULT)
  end

  it "finds available downloads" do
    available = Solargraph::YardMap::CoreDocs.available
    expect(available).not_to be_empty
  end

  it "finds the best download" do
    available = Solargraph::YardMap::CoreDocs.available
    best_match = Solargraph::YardMap::CoreDocs.best_download
    expect(available).to include(best_match)
  end

  it "finds the best download for future versions" do
    best_match = Solargraph::YardMap::CoreDocs.best_download('99.99.99')
    expect(best_match).not_to be_nil
  end

  it "downloads the best match" do
    best_match = Solargraph::YardMap::CoreDocs.best_download
    Solargraph::YardMap::CoreDocs.download best_match
    expect(Solargraph::YardMap::CoreDocs.valid?(best_match)).to be(true)
  end

  it "clears the cache" do
    expect {
      Solargraph::YardMap::CoreDocs.clear
    }.not_to raise_error
    expect(Solargraph::YardMap::CoreDocs.best_match).to eq(Solargraph::YardMap::CoreDocs::DEFAULT)
  end
end
