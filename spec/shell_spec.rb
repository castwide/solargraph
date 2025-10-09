# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  let(:shell) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    File.open(File.join(temp_dir, 'Gemfile'), 'w') do |file|
        file.puts "source 'https://rubygems.org'"
        file.puts "gem 'solargraph', path: '#{File.expand_path('..', __dir__)}'"
    end
    output, status = Open3.capture2e("bundle install", chdir: temp_dir)
    raise "Failure installing bundle: #{output}" unless status.success?
  end

  # @type cmd [Array<String>]
  # @return [String]
  def bundle_exec(*cmd)
    # run the command in the temporary directory with bundle exec
    output, status = Open3.capture2e("bundle exec #{cmd.join(' ')}", chdir: temp_dir)
    expect(status.success?).to be(true), "Command failed: #{output}"
    output
  end

  after do
    # remove the temporary directory after the tests
    FileUtils.rm_rf(temp_dir)
  end

  describe '--version' do
    let(:output) { bundle_exec('solargraph', '--version') }

    it 'returns output' do
      expect(output).not_to be_empty
    end

    it 'returns a version when run' do
      expect(output).to eq("#{Solargraph::VERSION}\n")
    end
  end

  describe 'uncache' do
    it 'uncaches without erroring out' do
      output = capture_stdout do
        shell.uncache('backport')
      end

      expect(output).to include('Clearing pin cache in')
    end

    it 'uncaches stdlib without erroring out' do
      expect { shell.uncache('stdlib') }.not_to raise_error
    end

    it 'uncaches core without erroring out' do
      expect { shell.uncache('core') }.not_to raise_error
    end
  end

  describe 'scan' do
    context 'with mocked dependencies' do
      let(:api_map) { instance_double(Solargraph::ApiMap) }

      before do
        allow(Solargraph::ApiMap).to receive(:load_with_cache).and_return(api_map)
      end

      it 'scans without erroring out' do
        allow(api_map).to receive(:pins).and_return([])
        output = capture_stdout do
          shell.options = { directory: 'spec/fixtures/workspace' }
          shell.scan
        end

        expect(output).to include('Scanned ').and include(' seconds.')
      end
    end
  end

  describe 'typecheck' do
    context 'with mocked dependencies' do
      let(:type_checker) { instance_double(Solargraph::TypeChecker) }
      let(:api_map) { instance_double(Solargraph::ApiMap) }

      before do
        allow(Solargraph::ApiMap).to receive(:load_with_cache).and_return(api_map)
        allow(Solargraph::TypeChecker).to receive(:new).and_return(type_checker)
        allow(type_checker).to receive(:problems).and_return([])
      end

      it 'typechecks without erroring out' do
        output = capture_stdout do
          shell.options = { level: 'normal', directory: '.' }
          shell.typecheck('Gemfile')
        end

        expect(output).to include('Typecheck finished in')
      end
    end
  end

  describe 'gems' do
    context 'without mocked ApiMap' do
      it 'complains when gem does not exist' do
        pending 'error message improvements'

        output = capture_both do
          shell.gems('nonexistentgem')
        end

        expect(output).to include("Gem 'nonexistentgem' not found")
      end

      it 'caches core without erroring out' do
        pending 'core caching suppport'

        capture_both do
          shell.uncache('core')
        end

        expect { shell.cache('core') }.not_to raise_error
      end

      it 'gives sensible error for gem that does not exist' do
        pending 'error message improvements'

        output = capture_both do
          shell.gems('solargraph123')
        end

        expect(output).to include("Gem 'solargraph123' not found")
      end
    end

    context 'with mocked Workspace' do
      let(:api_map) { instance_double(Solargraph::ApiMap) }
      let(:workspace) { instance_double(Solargraph::Workspace) }
      let(:gemspec) { instance_double(Gem::Specification, name: 'backport') }

      before do
        allow(Solargraph::Workspace).to receive(:new).and_return(workspace)
        allow(Solargraph::ApiMap).to receive(:load).with('.').and_return(api_map)
        allow(api_map).to receive(:cache_gem)
        allow(api_map).to receive(:workspace).and_return(workspace)
      end

      it 'caches all without erroring out' do
        pending 'delegation to api_map'

        allow(api_map).to receive(:cache_all!)

        _output = capture_both { shell.gems }

        expect(api_map).to have_received(:cache_all!)
      end

      it 'caches single gem without erroring out' do
        allow(workspace).to receive(:find_gem).with('backport').and_return(gemspec)

        capture_both do
          shell.options = { rebuild: false }
          shell.gems('backport')
        end

        expect(api_map).to have_received(:cache_gem).with(gemspec, out: an_instance_of(StringIO), rebuild: false)
      end
    end
  end

  describe 'cache' do
    it 'caches a stdlib gem without erroring out' do
      expect { shell.cache('stringio') }.not_to raise_error
    end

    context 'when gem does not exist' do
      subject(:call) { shell.cache('nonexistentgem8675309') }

      it 'gives a good error message' do
        pending 'better error message'

        # capture stderr output
        expect { call }.to output(/not found/).to_stderr
      end
    end
  end
end
