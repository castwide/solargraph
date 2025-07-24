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

    context 'with abbrev from stdlib' do
      let(:name) { 'abbrev' }
      let(:version) { nil }

      it 'returns no gemspec' do
        expect(gemspec).to be_nil
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

        expect(out.string).to include('install the gem checkoff')
      end
    end
  end
end
