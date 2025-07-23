# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rubygems/commands/install_command'

describe Solargraph::Workspace::Gemspecs, '#resolve_require' do
  subject(:specs) { gemspecs.resolve_require(require) }

  let(:gemspecs) { described_class.new(dir_path) }

  def find_or_install gem_name, version
    Gem::Specification.find_by_name(gem_name, version)
  rescue Gem::LoadError
    install_gem(gem_name, version)
  end

  def install_gem gem_name, version
    Bundler.with_unbundled_env do
      cmd = Gem::Commands::InstallCommand.new
      cmd.handle_options [gem_name, '-v', version]
      cmd.execute
    rescue Gem::SystemExitException => e
      raise unless e.exit_code == 0
    end
  end

  context 'with local bundle' do
    let(:dir_path) { File.realpath(Dir.pwd) }

    context 'with a known gem' do
      let(:require) { 'solargraph' }

      it 'returns a single spec' do
        expect(specs.size).to eq(1)
      end

      it 'resolves to the right known gem' do
        expect(specs.map(&:name)).to eq(['solargraph'])
      end
    end

    context 'with a less usual require mapping' do
      let(:require) { 'diff/lcs' }

      it 'returns a single spec' do
        expect(specs.size).to eq(1)
      end

      it 'resolves to the right known gem' do
        expect(specs.map(&:name)).to eq(['diff-lcs'])
      end
    end

    context 'with Bundler.require' do
      let(:require) { 'bundler/require' }

      it 'returns the gemspec gem' do
        expect(specs.map(&:name)).to include('solargraph')
      end
    end
  end

  context 'with external bundle' do
    let(:dir_path) { File.realpath(Dir.mktmpdir).to_s }

    before do
      # write out Gemfile
      File.write(File.join(dir_path, 'Gemfile'), <<~GEMFILE)
        source 'https://rubygems.org'
        gem 'backport'
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

    context 'with a gem preference' do
      before do
        find_or_install('backport', '1.0.0')
        Gem::Specification.find_by_name('backport', '= 1.0.0')
      end

      let(:preferences) do
        [
          Gem::Specification.new.tap do |spec|
            spec.name = 'backport'
            spec.version = '1.0.0'
          end
        ]
      end

      it 'returns the preferred gemspec' do
        gemspecs = described_class.new(dir_path, preferences: preferences)
        specs = gemspecs.resolve_require('backport')
        backport = specs.find { |spec| spec.name == 'backport' }

        expect(backport.version.to_s).to eq('1.0.0')
      end
    end
  end
end
