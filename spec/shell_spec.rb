# frozen_string_literal: true

require 'tmpdir'
require 'open3'

describe Solargraph::Shell do
  let(:shell) { described_class.new }

  let(:temp_dir) { Dir.mktmpdir }

  before do
    File.open(File.join(temp_dir, 'Gemfile'), 'w') do |file|
        file.puts "source 'https://rubygems.org'"
        file.puts "gem 'solargraph', path: #{File.expand_path('..', __dir__)}"
    end
    output, status = Open3.capture2e("bundle install", chdir: temp_dir)
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

  describe "--version" do
    it "returns a version when run" do
      output = bundle_exec("solargraph", "--version")

      expect(output).not_to be_empty
      expect(output).to eq("#{Solargraph::VERSION}\n")
    end
  end

  describe "uncache" do
    it "uncaches without erroring out" do
      output = bundle_exec("solargraph", "uncache", "solargraph")

      expect(output).to include('Clearing pin cache in')
    end
  end

  # @type cmd [Array<String>]
  # @return [String]
  def bundle_exec(*cmd)
    # run the command in the temporary directory with bundle exec
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e("bundle exec #{cmd.join(' ')}")
      expect(status.success?).to be(true), "Command failed: #{output}"
      output
    end
  end

  describe 'pin' do
    let(:api_map) { instance_double(Solargraph::ApiMap) }
    let(:to_s_pin) { instance_double(Solargraph::Pin::Method, return_type: Solargraph::ComplexType.parse('String')) }

    before do
      allow(Solargraph::ApiMap).to receive(:load_with_cache).and_return(api_map)
      allow(api_map).to receive(:get_path_pins).with('String#to_s').and_return([to_s_pin])
    end

    context 'with no options' do
      it 'prints a pin' do
        allow(to_s_pin).to receive(:inspect).and_return('pin inspect result')

        out = capture_both { shell.pin('String#to_s') }

        expect(out).to eq("pin inspect result\n")
      end
    end

    context 'with --rbs option' do
      it 'prints a pin with RBS type' do
        allow(to_s_pin).to receive(:to_rbs).and_return('pin RBS result')

        out = capture_both do
          shell.options = { rbs: true }
          shell.pin('String#to_s')
        end
        expect(out).to eq("pin RBS result\n")
      end
    end

    context 'with --stack option' do
      it 'prints a pin using stack results' do
        allow(to_s_pin).to receive(:to_rbs).and_return('pin RBS result')

        allow(api_map).to receive(:get_method_stack).and_return([to_s_pin])
        capture_both do
          shell.options = { stack: true }
          shell.pin('String#to_s')
        end
        expect(api_map).to have_received(:get_method_stack).with('String', 'to_s', scope: :instance)
      end

      it 'prints a static pin using stack results' do
        # allow(to_s_pin).to receive(:to_rbs).and_return('pin RBS result')
        string_new_pin = instance_double(Solargraph::Pin::Method, return_type: Solargraph::ComplexType.parse('String'))

        allow(api_map).to receive(:get_method_stack).with('String', 'new', scope: :class).and_return([string_new_pin])
        capture_both do
          shell.options = { stack: true }
          shell.pin('String.new')
        end
        expect(api_map).to have_received(:get_method_stack).with('String', 'new', scope: :class)
      end
    end

    context 'with --typify option' do
      it 'prints a pin with typify type' do
        allow(to_s_pin).to receive(:typify).and_return(Solargraph::ComplexType.parse('::String'))

        out = capture_both do
          shell.options = { typify: true }
          shell.pin('String#to_s')
        end
        expect(out).to eq("::String\n")
      end
    end

    context 'with --typify --rbs options' do
      it 'prints a pin with typify type' do
        allow(to_s_pin).to receive(:typify).and_return(Solargraph::ComplexType.parse('::String'))

        out = capture_both do
          shell.options = { typify: true, rbs: true }
          shell.pin('String#to_s')
        end
        expect(out).to eq("::String\n")
      end
    end

    context 'with no pin' do
      it 'prints error' do
        allow(api_map).to receive(:get_path_pins).with('Not#found').and_return([])

        out = capture_both do
          shell.options = {}
          shell.pin('Not#found')
        rescue SystemExit
          # Ignore the SystemExit raised by the shell when no pin is found
        end
        expect(out).to include("Pin not found for path 'Not#found'")
      end
    end
  end
end
