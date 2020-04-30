require 'tmpdir'

describe Solargraph::YardMap::RdocToYard do
  it 'converts rdoc to yard' do
    Dir.mktmpdir do |tmpdir|
      file = File.join('spec', 'fixtures', 'rdoc-lib', 'rdoc-lib.gemspec')
      # @type [Gem::Specification]
      spec = eval(File.read(file), binding, file)
      spec.full_gem_path = File.join('spec', 'fixtures', 'rdoc-lib')
      Solargraph::YardMap::RdocToYard.run(spec, cache_dir: tmpdir)
      YARD::Registry.load tmpdir
      obj = YARD::Registry.at('Example#example')
      expect(obj).to be_a(YARD::CodeObjects::MethodObject)
    end
  end
end
