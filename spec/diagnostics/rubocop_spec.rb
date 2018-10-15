describe Solargraph::Diagnostics::Rubocop do
  before :each do
    @source = Solargraph::Source.new(%(
      class Foo
        def bar
        end
      end
      foo = Foo.new
    ), "#{dir_path}/file.rb")

    @api_map = Solargraph::ApiMap.new
    @api_map.map @source
  end

  let(:dir_path) { File.realpath(Dir.mktmpdir) }
  after(:each) { FileUtils.remove_entry(dir_path) }

  it "diagnoses input" do
    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(@source, @api_map)
    expect(result).to be_a(Array)
    expect(result).not_to be_empty
  end

  it "ignores excluded files from diagnoses output" do
    file = File.join(dir_path, '.rubocop.yml')
    File.write(file, <<-CONTENTS
AllCops:
  Exclude:
    - 'file.rb'
CONTENTS
)
    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(@source, @api_map, { 'arguments' => '--force-exclusion --lint' })
    expect(result).to be_a(Array)
    expect(result).to be_empty
  end

  it "still reports non-excluded files in diagnoses output" do
    file = File.join(dir_path, '.rubocop.yml')
    File.write(file, <<-CONTENTS
AllCops:
  Exclude:
    - 'file2.rb'
CONTENTS
)
    rubocop = Solargraph::Diagnostics::Rubocop.new
    result = rubocop.diagnose(@source, @api_map, { 'arguments' => '--force-exclusion' })
    expect(result).to be_a(Array)
    expect(result.count).to eq(6)

    result = rubocop.diagnose(@source, @api_map, { 'arguments' => '--force-exclusion --lint' })
    expect(result.count).to eq(1)
  end
end
