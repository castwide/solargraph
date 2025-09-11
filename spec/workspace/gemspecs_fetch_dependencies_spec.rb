# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require 'rubygems/commands/install_command'

describe Solargraph::Workspace::Gemspecs, '#fetch_dependencies' do
  subject(:deps) { gemspecs.fetch_dependencies(gemspec) }

  let(:gemspecs) { described_class.new(dir_path) }
  let(:dir_path) { Dir.pwd }

  context 'when in our bundle' do
    context 'with a Bundler::LazySpecification' do
      let(:gemspec) do
        Bundler::LazySpecification.new('solargraph', nil, nil)
      end

      it 'finds a known dependency' do
        pending('https://github.com/castwide/solargraph/pull/1006')
        expect(deps.map(&:name)).to include('backport')
      end
    end

    context 'with gem whose dependency does not exist in our bundle' do
      let(:gemspec) do
        instance_double(Gem::Specification,
                        dependencies: [Gem::Dependency.new('activerecord')],
                        development_dependencies: [],
                        name: 'my_fake_gem',
                        version: '123')
      end
      let(:gem_name) { 'my_fake_gem' }

      it 'gives a useful message' do
        pending('https://github.com/castwide/solargraph/pull/1006')

        output = capture_both { deps.map(&:name) }
        expect(output).to include('Please install the gem activerecord')
      end
    end
  end

  context 'with external bundle' do
    let(:dir_path) { File.realpath(Dir.mktmpdir).to_s }

    let(:gemspec) do
      Gem::Specification.find_by_name(gem_name)
    end

    before do
      # write out Gemfile
      File.write(File.join(dir_path, 'Gemfile'), <<~GEMFILE)
        source 'https://rubygems.org'
        gem '#{gem_name}'
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

    context 'with gem that exists in our bundle' do
      let(:gem_name) { 'undercover' }

      it 'finds dependencies' do
        expect(deps.map(&:name)).to include('ast')
      end
    end

    context 'with gem does not exist in our bundle' do
      let(:gemspec) do
        Gem::Specification.new(fake_gem_name)
      end

      let(:gem_name) { 'undercover' }

      let(:fake_gem_name) { 'faaaaaake912' }

      it 'gives a useful message' do
        pending('https://github.com/castwide/solargraph/pull/1006')
        dep_names = nil
        output = capture_both { dep_names = deps.map(&:name) }
        expect(output).to include('Please install the gem activerecord')
      end
    end
  end
end
