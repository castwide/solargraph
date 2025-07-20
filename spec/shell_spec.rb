# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  let(:temp_dir) { Dir.mktmpdir }

  before do
    File.open(File.join(temp_dir, 'Gemfile'), 'w') do |file|
      file.puts "source 'https://rubygems.org'"
      file.puts "gem 'solargraph', path: '#{File.expand_path('..', __dir__)}'"
    end
    output, status = Open3.capture2e('bundle install', chdir: temp_dir)
    raise "Failure installing bundle: #{output}" unless status.success?
  end

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
      output = bundle_exec('solargraph', 'uncache', 'solargraph')

      expect(output).to include('Clearing pin cache in')
    end
  end

  describe 'gem' do
    it 'caches without erroring out' do
      output = bundle_exec('solargraph', 'gem', 'solargraph')

      expect(output).to include('Caching these gems')
    end
  end

  describe 'gems' do
    it 'caches all without erroring out' do
      output = bundle_exec('solargraph', 'gems')

      expect(output).to include('Documentation cached for all')
    end
  end

  describe 'cache' do
    it 'caches without erroring out' do
      output = bundle_exec('solargraph', 'cache', 'solargraph')

      expect(output).to include('Caching these gems')
    end
  end
end
