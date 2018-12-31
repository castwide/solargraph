describe Solargraph::LanguageServer::Host::Dispatch do
  before :all do
    @dispatch = Solargraph::LanguageServer::Host::Dispatch
  end

  after :each do
    @dispatch.libraries.clear
    @dispatch.sources.clear
  end

  it "finds an explicit library" do
    @dispatch.libraries.push Solargraph::Library.load('*')
    src = @dispatch.sources.open('file:///file.rb', 'a=b', 0)
    @dispatch.libraries.first.merge src
    lib = @dispatch.library_for('file:///file.rb')
    expect(lib).to be(@dispatch.libraries.first)
  end

  it "finds an implicit library" do
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    file = File.join(dir, 'new.rb')
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    @dispatch.libraries.push Solargraph::Library.load(dir)
    @dispatch.sources.open uri, 'a=b', 0
    lib = @dispatch.library_for(uri)
    expect(lib).to be(@dispatch.libraries.first)
  end

  it "finds a generic library" do
    dir = File.realpath(File.join('spec', 'fixtures', 'workspace'))
    file = '/external.rb'
    uri = Solargraph::LanguageServer::UriHelpers.file_to_uri(file)
    @dispatch.libraries.push Solargraph::Library.load(dir)
    @dispatch.sources.open uri, 'a=b', 0
    lib = @dispatch.library_for(uri)
    expect(lib).to be(@dispatch.generic_library)
  end
end
