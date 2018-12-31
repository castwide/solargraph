describe Solargraph::Diagnostics::RubocopHelpers do
  it "finds a .rubocop.yml file in a parent directory" do
    file = File.realpath(File.join 'spec', 'fixtures', 'rubocop-subfolder-configuration', 'folder1', 'folder2', 'test.rb')
    conf = File.realpath(File.join 'spec', 'fixtures', 'rubocop-subfolder-configuration', '.rubocop.yml')
    found = Solargraph::Diagnostics::RubocopHelpers.find_rubocop_file(file)
    expect(found).to eq(conf)
  end

  it "converts lower-case drive letters to upper-case" do
    input = 'c:/one/two'
    output = Solargraph::Diagnostics::RubocopHelpers.fix_drive_letter(input)
    expect(output).to eq('C:/one/two')
  end

  it "ignores paths without drive letters" do
    input = 'one/two'
    output = Solargraph::Diagnostics::RubocopHelpers.fix_drive_letter(input)
    expect(output).to eq('one/two')
  end
end
