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

  def add_bundle
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
    return if File.exist?(File.join(dir_path, 'Gemfile.lock'))
    raise "Gemfile.lock not found after bundle install in #{dir_path}"
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

    context 'with an unknown type from Bundler / RubyGems' do
      let(:require) { 'solargraph' }
      let(:specish_objects) { [double] }

      before do
        lockfile = instance_double(Pathname)
        locked_gems = instance_double(Bundler::LockfileParser, specs: specish_objects)

        definition = instance_double(Bundler::Definition,
                                     locked_gems: locked_gems,
                                     lockfile: lockfile)
        allow(Bundler).to receive(:definition).and_return(definition)
        allow(lockfile).to receive(:to_s).and_return(dir_path)
      end

      it 'returns a single spec' do
        expect(specs.size).to eq(1)
      end

      it 'resolves to the right known gem' do
        expect(specs.map(&:name)).to eq(['solargraph'])
      end
    end

    def configure_bundler_spec stub_value
      platform = Gem::Platform::RUBY
      bundler_stub_spec = Bundler::StubSpecification.new('solargraph', '123', platform, spec_fetcher)
      specish_objects = [bundler_stub_spec]
      lockfile = instance_double(Pathname)
      locked_gems = instance_double(Bundler::LockfileParser, specs: specish_objects)
      definition = instance_double(Bundler::Definition,
                                   locked_gems: locked_gems,
                                   lockfile: lockfile)
      # specish_objects = Bundler.definition.locked_gems.specs
      allow(Bundler).to receive(:definition).and_return(definition)
      allow(lockfile).to receive(:to_s).and_return(dir_path)
      allow(bundler_stub_spec).to receive(:respond_to?).with(:name).and_return(true)
      allow(bundler_stub_spec).to receive(:respond_to?).with(:version).and_return(true)
      allow(bundler_stub_spec).to receive(:respond_to?).with(:gem_dir).and_return(false)
      allow(bundler_stub_spec).to receive(:respond_to?).with(:materialize_for_installation).and_return(false)
      allow(bundler_stub_spec).to receive_messages(name: 'solargraph', stub: stub_value)
    end

    context 'with a Bundler::StubSpecification from Bundler / RubyGems' do
      # this can happen from local gems, which is hard to test
      # organically

      let(:require) { 'solargraph' }
      let(:spec_fetcher) { instance_double(Gem::SpecFetcher) }

      before do
        platform = Gem::Platform::RUBY
        real_spec = instance_double(Gem::Specification)
        allow(real_spec).to receive(:name).and_return('solargraph')
        gem_stub_spec = Gem::StubSpecification.new('solargraph', '123', platform, spec_fetcher)
        configure_bundler_spec(gem_stub_spec)
        allow(gem_stub_spec).to receive_messages(name: 'solargraph', version: '123', spec: real_spec)
      end

      it 'returns a single spec' do
        expect(specs.size).to eq(1)
      end

      it 'resolves to the right known gem' do
        expect(specs.map(&:name)).to eq(['solargraph'])
      end
    end

    context 'with a Bundler::StubSpecification that resolves straight to Gem::Specification' do
      # have seen different behavior with different versions of rubygems/bundler

      let(:require) { 'solargraph' }
      let(:spec_fetcher) { instance_double(Gem::SpecFetcher) }
      let(:real_spec) { Gem::Specification.new('solargraph', '123') }

      before do
        configure_bundler_spec(real_spec)
      end

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
        pending('https://github.com/castwide/solargraph/pull/1006')

        expect(specs).to be_empty
      end
    end
  end

  context 'with external bundle' do
    let(:dir_path) { File.realpath(Dir.mktmpdir).to_s }

    context 'with no actual bundle' do
      let(:require) { 'bundler/require' }

      it 'raises' do
        pending('https://github.com/castwide/solargraph/pull/1006')

        expect { specs }.to raise_error(Solargraph::BundleNotFoundError)
      end
    end

    context 'with Gemfile and Bundler.require' do
      before { add_bundle }

      let(:require) { 'bundler/require' }

      it 'does not raise' do
        expect { specs }.not_to raise_error
      end

      it 'returns gems' do
        expect(specs.map(&:name)).to include('backport')
      end
    end

    context 'with Gemfile and deep require into a possibly-core gem' do
      before { add_bundle }

      let(:require) { 'bundler/gem_tasks' }

      xit 'returns gems' do
        pending('improved logic for require lookups')

        expect(specs&.map(&:name)).to include('bundler')
      end
    end

    context 'with Gemfile and deep require into a gem' do
      before { add_bundle }

      let(:require) { 'rspec/mocks' }

      it 'returns gems' do
        expect(specs&.map(&:name)).to include('rspec-mocks')
      end
    end

    context 'with Gemfile but an unknown gem' do
      before { add_bundle }

      let(:require) { 'unknown_gemlaksdflkdf' }

      it 'returns nil' do
        expect(specs).to be_nil
      end
    end

    context 'with a Gemfile and a gem preference' do
      # find_or_install helper doesn't seem to work on older versions
      if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1.0')
        before do
          add_bundle
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
          pending('https://github.com/castwide/solargraph/pull/1006')

          gemspecs = described_class.new(dir_path, preferences: preferences)
          specs = gemspecs.resolve_require('backport')
          backport = specs.find { |spec| spec.name == 'backport' }

          expect(backport.version.to_s).to eq('1.0.0')
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
            pending('https://github.com/castwide/solargraph/pull/1006')

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
