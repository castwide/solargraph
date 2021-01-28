describe Solargraph::Diagnostics::RubocopHelpers do
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
