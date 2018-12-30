describe Solargraph::Diagnostics::RubocopHelpers do
  it "finds a .rubocop.yml file in a parent directory" do
    file = File.realpath(File.join 'spec', 'fixtures', 'rubocop-subfolder-configuration', 'folder1', 'folder2', 'test.rb')
    conf = File.realpath(File.join 'spec', 'fixtures', 'rubocop-subfolder-configuration', '.rubocop.yml')
    found = Solargraph::Diagnostics::RubocopHelpers.find_rubocop_file(file)
    expect(found).to eq(conf)
  end
end
