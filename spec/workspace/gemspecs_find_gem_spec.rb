# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rubygems/commands/install_command'

describe Solargraph::Workspace::Gemspecs, '#find_gem' do
  subject(:gemspec) { gemspecs.find_gem(name, version, out: out) }

  let(:gemspecs) { described_class.new(dir_path) }
  let(:out) { StringIO.new }

  context 'with local bundle' do
    let(:dir_path) { File.realpath(Dir.pwd) }

    context 'with solargraph from bundle' do
      let(:name) { 'solargraph' }
      let(:version) { nil }

      it 'returns the gem' do
        expect(gemspec.name).to eq(name)
      end
    end

    context 'with random from core' do
      let(:name) { 'random' }
      let(:version) { nil }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
      end

      it 'does not complain' do
        expect(out.string).to be_empty
      end
    end

    context 'with ripper from core' do
      let(:name) { 'ripper' }
      let(:version) { nil }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
      end
    end

    context 'with base64 from stdlib' do
      let(:name) { 'base64' }
      let(:version) { nil }

      it 'returns a gemspec' do
        expect(gemspec).not_to be_nil
      end
    end

    context 'with gem not in bundle' do
      let(:name) { 'checkoff' }
      let(:version) { nil }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
      end

      it 'complains' do
        gemspec

        expect(out.string).to include('install the gem checkoff ')
      end
    end

    context 'with gem not in bundle but no logger' do
      let(:name) { 'checkoff' }
      let(:version) { nil }
      let(:out) { nil }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
      end

      it 'does not fail' do
        expect { gemspec }.not_to raise_error
      end
    end

    context 'with gem not in bundle with version' do
      let(:name) { 'checkoff' }
      let(:version) { '1.0.0' }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
      end

      it 'complains' do
        gemspec

        expect(out.string).to include('install the gem checkoff:1.0.0')
      end
    end
  end

  context 'when Solargraph itself is not running under a discoverable Gemfile' do
    # Regression test: Bundler.definition raises Bundler::GemfileNotFound
    # (rather than returning nil) when no Gemfile is discoverable from the
    # current process, e.g. when Solargraph is installed and invoked as a
    # standalone gem. #in_this_bundle? must not let that exception escape.
    let(:dir_path) { File.realpath(Dir.mktmpdir) }
    let(:name) { 'solargraph' }
    let(:version) { nil }

    before do
      allow(Bundler).to receive(:definition).and_raise(Bundler::GemfileNotFound, 'Could not locate Gemfile')
    end

    it 'falls back to resolving gems ignoring any local bundle instead of raising' do
      expect { gemspec }.not_to raise_error
      expect(gemspec.name).to eq(name)
    end
  end
end
