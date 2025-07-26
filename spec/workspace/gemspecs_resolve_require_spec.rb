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

  context 'with nil as directory' do
    let(:dir_path) { nil }

    context 'with simple require' do
      let(:require) { 'solargraph' }

      it 'finds solargraph' do
        expect(specs.map(&:name)).to eq(['solargraph'])
      end
    end

    context 'with Bundler.require' do
      let(:require) { 'bundler/require' }

      it 'finds nothing' do
        expect(specs).to be_empty
      end
    end
  end

  context 'with external bundle' do
    let(:dir_path) { File.realpath(Dir.mktmpdir).to_s }

    context 'with no actual bundle' do
      let(:require) { 'bundler/require' }

      it 'raises' do
        expect { specs }.to raise_error(Solargraph::BundleNotFoundError)
      end
    end

    context 'with Gemfile' do
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

      let(:require) { 'bundler/require' }

      it 'does not raise' do
        expect { specs }.not_to raise_error
      end

      it 'returns gems' do
        expect(specs.map(&:name)).to include('backport')
      end

      # find_or_install helper doesn't seem to work on older versions
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1.0')
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

        context 'with a gem preference that does not exist' do
          let(:preferences) do
            [
              Gem::Specification.new.tap do |spec|
                spec.name = 'backport'
                spec.version = '99.0.0'
              end
            ]
          end

          it 'returns the gemspec we do have' do
            gemspecs = described_class.new(dir_path, preferences: preferences)
            specs = gemspecs.resolve_require('backport')
            backport = specs.find { |spec| spec.name == 'backport' }

            expect(backport.version.to_s).to eq('1.2.0')
          end
        end

        context 'with a gem preference already set to the version we use' do
          let(:version) { Gem::Specification.find_by_name('backport').version.to_s }

          let(:preferences) do
            [
              Gem::Specification.new.tap do |spec|
                spec.name = 'backport'
                spec.version = version
              end
            ]
          end

          it 'returns the gemspec we do have' do
            gemspecs = described_class.new(dir_path, preferences: preferences)
            specs = gemspecs.resolve_require('backport')
            backport = specs.find { |spec| spec.name == 'backport' }

            expect(backport.version.to_s).to eq(version)
          end
        end
      end
    end
  end
end
