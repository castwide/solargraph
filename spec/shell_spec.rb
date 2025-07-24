# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  let(:shell) {  described_class.new }

  let(:temp_dir) { Dir.mktmpdir }

  before do
    File.open(File.join(temp_dir, 'Gemfile'), 'w') do |file|
      file.puts "source 'https://rubygems.org'"
      file.puts "gem 'solargraph', path: '#{File.expand_path('..', __dir__)}'"
    end
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e('bundle install', chdir: temp_dir)
      raise "Failure installing bundle: #{output}" unless status.success?
    end
  end

  # @type cmd [Array<String>]
  # @return [String]
  def bundle_exec(*cmd)
    # run the command in the temporary directory with bundle exec
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e("bundle exec #{cmd.join(' ')}", chdir: temp_dir)
      expect(status.success?).to be(true), "Command failed: #{output}"
      output
    end
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

  describe 'typecheck' do
    it 'typechecks without erroring out' do
      output = capture_stdout do
        old_options = shell.options
        shell.options = { level: 'normal', directory: '.', **old_options }
        shell.typecheck('Gemfile')
      end

      expect(output).to include('Typecheck finished in')
    end

    it 'caches a gem if needed before typechecking' do
      capture_both do
        shell.uncache('backport')
      end

      output = capture_both do
        shell.options = { level: 'normal', directory: Dir.pwd }
        shell.typecheck('Gemfile')
      end

      expect(output).to include('Caching ').and include('backport')
    end
  end

  describe 'gems' do
    it 'caches core without erroring out' do
      expect { shell.cache('core') }.not_to raise_error
    end

    it 'has a well set up test environment' do
      output = bundle_exec('bundle', 'list')

      expect(output).to include('language_server-protocol')
    end

    it 'caches all without erroring out' do
      output = bundle_exec('solargraph', 'gems')

      expect(output).to include('Documentation cached for all')
    end

    it 'caches single gem without erroring out' do
      capture_both do
        shell.uncache('backport')
      end

      output = capture_both do
        shell.gems('backport')
      end

      expect(output).to include('Caching').and include('backport')
    end

    it 'gives sensible error for gem that does not exist' do
      output = capture_both do
        shell.gems('solargraph123')
      end

      expect(output).to include("Gem 'solargraph123' not found")
    end

    it 'caches all gems as needed' do
      shell = described_class.new
      _output = capture_stdout do
        shell.uncache('backport')
      end

      _output = capture_stdout do
        shell.gems
      end

      api_map = Solargraph::ApiMap.load(Dir.pwd)
      methods = api_map.get_method_stack('Backport::Adapter', 'remote')
      expect(methods.first.return_type.tag).to eq('Hash{Symbol => String, Integer}')
    end

    it 'caches a YARD-using gem and loads pins' do
      shell = described_class.new
      _output = capture_stdout do
        shell.uncache('backport')
      end

      _output = capture_stdout do
        shell.gems('backport')
      end

      api_map = Solargraph::ApiMap.load(Dir.pwd)
      methods = api_map.get_method_stack('Backport::Adapter', 'remote')
      expect(methods.first.return_type.tag).to eq('Hash{Symbol => String, Integer}')
    end
  end

  describe 'cache' do
    it 'caches a stdlib gem without erroring out' do
      expect { shell.cache('stringio') }.not_to raise_error
    end

    it 'caches gem without erroring out' do
      _output = capture_stdout do
        shell.uncache('backport')
      end

      output = capture_both do
        shell.cache('backport')
      end

      expect(output).to include('Caching').and include('backport')
    end
  end
end
