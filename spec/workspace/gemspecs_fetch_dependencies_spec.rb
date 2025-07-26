# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rubygems/commands/install_command'

describe Solargraph::Workspace::Gemspecs, '#fetch_dependencies' do
  subject(:deps) { gemspecs.fetch_dependencies(gemspec) }

  let(:gemspecs) { described_class.new(dir_path) }
  let(:dir_path) { Dir.pwd }

  context 'with a Bundler::LazySpecification in bundle' do
    let(:gemspec) do
      Bundler::LazySpecification.new('solargraph', nil, nil)
    end

    it 'finds a known dependency' do
      expect(deps.map(&:name)).to include('backport')
    end
  end

  context 'with external bundle' do
    let(:dir_path) { File.realpath(Dir.mktmpdir).to_s }

    let(:gemspec) do
      Bundler::LazySpecification.new('undercover', nil, nil)
    end

    before do
      # write out Gemfile
      File.write(File.join(dir_path, 'Gemfile'), <<~GEMFILE)
        source 'https://rubygems.org'
        gem 'undercover'
      GEMFILE

      # run bundle install
      output, status = Solargraph.with_clean_env do
        Open3.capture2e('bundle install --verbose', chdir: dir_path)
      end
      raise "Failure installing bundle: #{output}" unless status.success?

      # ensure Gemfile.lock exists
      unless File.exist?(File.join(dir_path, 'Gemfile.lock'))
        raise "Gemfile.lock not found after bundle install in #{dir_path}"
      end
    end

    it 'finds dependencies' do
      expect(deps.map(&:name)).to include('ast')
    end
  end
end
