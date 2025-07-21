# frozen_string_literal: true

require 'tmpdir'

describe Solargraph::Yardoc do
  describe '#build_docs' do
    around do |testobj|
      @tmpdir = Dir.mktmpdir

      testobj.run
    ensure
      FileUtils.remove_entry(@tmpdir) # rubocop:disable RSpec/InstanceVariable
    end

    it 'builds docs for a gem' do
      gem_yardoc_path = File.join(@tmpdir, 'solargraph', 'yardoc', 'test_gem') # rubocop:disable RSpec/InstanceVariable
      api_map = Solargraph::ApiMap.load(Dir.pwd)
      gem = api_map.find_gem('rubocop')
      described_class.build_docs(gem.gem_yardoc_path, [], gemspec)
      expect(File.exist?(File.join(gem_yardoc_path, 'complete'))).to be true
    end
  end
end
