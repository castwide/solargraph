require 'tmpdir'
require 'fileutils'

describe Solargraph::YardMap::RdocToYard do
  before :all do
    @tmpdir = Dir.mktmpdir
    file = File.join('spec', 'fixtures', 'rdoc-lib', 'rdoc-lib.gemspec')
    # @type [Gem::Specification]
    spec = eval(File.read(file), binding, file)
    spec.full_gem_path = File.join('spec', 'fixtures', 'rdoc-lib')
    Solargraph::YardMap::RdocToYard.run(spec, cache_dir: @tmpdir)
    YARD::Registry.load @tmpdir
  end

  after :all do
    FileUtils.remove_dir @tmpdir
  end

  it 'converts rdoc to yard' do
    obj = YARD::Registry.at('Example#example')
    expect(obj).to be_a(YARD::CodeObjects::MethodObject)
  end

  it 'includes line numbers for namespaces' do
    obj = YARD::Registry.at('Example')
    expect(obj.line).to eq(2)
  end

  it 'includes line numbers for methods' do
    obj = YARD::Registry.at('Example#example')
    expect(obj.line).to eq(4)
  end
end
