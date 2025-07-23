# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

describe Solargraph::Workspace::RequirePaths do
  subject(:paths) { described_class.new(dir_path, config).generate }

  let(:config) { Solargraph::Workspace::Config.new(dir_path) }

  context 'with no config' do
    let(:dir_path) { Dir.pwd }
    let(:config) { nil }

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end
  end

  context 'with config and no gemspec' do
    let(:dir_path) { File.realpath(Dir.pwd) }

    let(:config) { instance_double(Solargraph::Workspace::Config, require_paths: [], allow?: true) }

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end
  end

  context 'with current bundle' do
    let(:dir_path) { Dir.pwd }

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end

    it 'queried via Open3.capture3' do
      allow(Open3).to receive(:capture3).and_call_original

      paths

      expect(Open3).to have_received(:capture3)
    end
  end

  context 'with an invalid gemspec file' do
    let(:dir_path) { File.realpath(Dir.mktmpdir) }
    let(:gemspec_file) { File.join(dir_path, 'invalid.gemspec') }

    before do
      File.write(gemspec_file, 'bogus')
    end

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end

    it 'does not raise an error' do
      expect { paths }.not_to raise_error
    end
  end

  context 'with a valid gemspec file that outputs to stdout' do
    let(:dir_path) { File.realpath(Dir.mktmpdir) }
    let(:gemspec_file) { File.join(dir_path, 'invalid.gemspec') }

    before do
      File.write(gemspec_file, "print '{'; Gem::Specification.new")
    end

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end

    it 'does not raise an error' do
      expect { paths }.not_to raise_error
    end
  end

  context 'with no gemspec file' do
    let(:dir_path) { File.realpath(Dir.mktmpdir) }

    it 'includes the lib directory' do
      expect(paths).to include(File.join(dir_path, 'lib'))
    end
  end
end
