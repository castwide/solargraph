require 'fileutils'
require 'tmpdir'

describe Solargraph::YardMap::CoreDocs do
  before :each do
    # Override the cache for testing
    @tmp_dir = Dir.mktmpdir
    @orig_env = ENV['SOLARGRAPH_CACHE']
    ENV['SOLARGRAPH_CACHE'] = @tmp_dir

    stub_request(:get, "https://solargraph.org/download/versions.json").
      with(
        headers: {
      'Accept'=>'*/*',
      'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Host'=>'solargraph.org',
      'User-Agent'=>'Ruby'
      }).
      to_return(status: 200, body: {
        status: 'ok',
        cores: ['2.6.0', '2.5.0', '2.4.0', '2.3.0', '2.2.0', '2.1.0']
      }.to_json, headers: {})

    @download_version = '2.2.2'

    stub_request(:get, "https://solargraph.org/download/#{@download_version}.tar.gz").
      with(
        headers: {
       'Accept'=>'*/*',
       'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       'Host'=>'solargraph.org',
       'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: File.read_binary("yardoc/#{@download_version}.tar.gz"), headers: {})

    stub_request(:get, "https://solargraph.org/download/99.99.99.tar.gz").
      with(
        headers: {
       'Accept'=>'*/*',
       'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       'Host'=>'solargraph.org',
       'User-Agent'=>'Ruby'
        }).
      to_return(status: 404, body: "", headers: {})
  end

  after :each do
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

  it "downloads requested versions" do
    Solargraph::YardMap::CoreDocs.download @download_version
    expect(Solargraph::YardMap::CoreDocs.valid?(@download_version)).to be(true)
  end

  it 'reverts to earliest match for legacy versions' do
    result = Solargraph::YardMap::CoreDocs.best_download('1.0.0')
    expect(result).to eq(Solargraph::YardMap::CoreDocs.available.last)
  end

  it 'clears the cache' do
    expect {
      Solargraph::YardMap::CoreDocs.clear
    }.not_to raise_error
    expect(Solargraph::YardMap::CoreDocs.best_match).to eq(Solargraph::YardMap::CoreDocs::DEFAULT)
  end

  it 'raises errors for invalid version downloads' do
    expect {
      Solargraph::YardMap::CoreDocs.download('99.99.99')
    }.to raise_error(ArgumentError)
  end
end
