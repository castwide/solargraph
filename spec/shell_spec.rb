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
    output, status = Open3.capture2e('bundle install', chdir: temp_dir)
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
        output = capture_both do
          shell.gems('nonexistentgem')
        end

        expect(output).to include("Gem 'nonexistentgem' not found")
      end

      it 'caches core without erroring out' do
        capture_both do
          shell.uncache('core')
        end

        expect { shell.cache('core') }.not_to raise_error
      end

      it 'gives sensible error for gem that does not exist' do
        output = capture_both do
          shell.gems('solargraph123')
        end

        expect(output).to include("Gem 'solargraph123' not found")
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
        # capture stderr output
        expect { call }.to output(/not found/).to_stderr
      end
    end

    # Yardoc.load! is the only step on the YARD path that both the DocMap and
    # the Collection implementations reach unconditionally, so these hold
    # whichever one is caching the gem.
    context 'with a gem whose RBS collection types make YARD redundant' do
      before do
        # Rebuild, so the decision under test is the suppression rather than
        # whatever the gem happens to have cached already. Thor reads the
        # option by symbol, so a plain string-keyed Hash reads back as nil.
        shell.options = Thor::CoreExt::HashWithIndifferentAccess.new('rebuild' => true)
        allow(Solargraph::Yardoc).to receive(:load!).and_call_original
      end

      it 'reads no YARD documentation for the gem' do
        shell.cache('parser')

        expect(Solargraph::Yardoc).not_to have_received(:load!)
      end

      it 'still resolves the types the gem RBS declares' do
        shell.cache('parser')
        pins = Solargraph::ApiMap.load('.').get_path_pins('Parser::AST::Node#children')

        expect(pins.map { |pin| pin.return_type.to_s }).to include('Array<self>')
      end

      it 'reads YARD documentation for a gem outside the list' do
        shell.cache('backport')

        expect(Solargraph::Yardoc).to have_received(:load!)
      end
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

  describe 'pin on a class' do
    let(:api_map) { instance_double(Solargraph::ApiMap) }
    let(:string_pin) { instance_double(Solargraph::Pin::Namespace, name: 'String') }

    before do
      allow(Solargraph::ApiMap).to receive(:load_with_cache).and_return(api_map)
      allow(Solargraph::Pin::Namespace).to receive(:===).with(string_pin).and_return(true)
      allow(string_pin).to receive(:return_type).and_return(Solargraph::ComplexType.parse('String'))
      allow(api_map).to receive(:get_path_pins).with('String').and_return([string_pin])
    end

    context 'with --references option' do
      let(:object_pin) { instance_double(Solargraph::Pin::Namespace, name: 'Object') }

      before do
        allow(Solargraph::Pin::Namespace).to receive(:===).with(object_pin).and_return(true)
        allow(api_map).to receive(:qualify_superclass).with('String').and_return('Object')
        allow(api_map).to receive(:get_path_pins).with('Object').and_return([object_pin])
      end

      it 'prints a pin with info' do
        out = capture_both do
          shell.options = { references: true }
          shell.pin('String')
        end
        expect(out).to include('# Superclass:')
      end
    end
  end

  describe 'pin on a method' do
    let(:api_map) { instance_double(Solargraph::ApiMap) }
    let(:to_s_pin) { instance_double(Solargraph::Pin::Method, return_type: Solargraph::ComplexType.parse('String')) }

    before do
      allow(Solargraph::Pin::Method).to receive(:===).with(to_s_pin).and_return(true)
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
        allow(Solargraph::Pin::Method).to receive(:===).with(string_new_pin).and_return(true)
        allow(api_map).to receive(:get_path_pins).with('String.new').and_return([string_new_pin])
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
        allow(Solargraph::Pin::Method).to receive(:===).with(nil).and_return(false)

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

  describe '#do_cache' do
    let(:pin) { Solargraph::Pin::Namespace.new(name: 'Foo') }

    before do
      workspace = instance_double(Solargraph::Workspace, rbs_collection_path: nil, rbs_collection_config_path: nil)
      allow(Solargraph::Workspace).to receive(:new).and_return(workspace)
      allow(Solargraph::PinCache).to receive_messages(has_yard?: false, has_rbs_collection?: false)
      allow(Solargraph::PinCache).to receive(:serialize_yard_gem)
      allow(Solargraph::PinCache).to receive(:serialize_rbs_collection_gem)
      allow(Solargraph::GemPins).to receive(:build_yard_pins).and_return([pin])
    end

    # @param name [String]
    # @param cache_key [String]
    # @return [Gem::Specification] the gemspec handed to do_cache
    def cache_gem name, cache_key
      gemspec = instance_double(Gem::Specification, name: name)
      rbs_map = instance_double(Solargraph::RbsMap, cache_key: cache_key, pins: [pin])
      allow(Solargraph::RbsMap).to receive(:from_gemspec).and_return(rbs_map)
      shell.send(:do_cache, gemspec)
      gemspec
    end

    it 'skips the YARD build when the RBS collection resolves types' do
      cache_gem('parser', 'resolved-key')

      expect(Solargraph::GemPins).not_to have_received(:build_yard_pins)
    end

    it 'caches RBS collection pins for a gem whose YARD build was skipped' do
      gemspec = cache_gem('parser', 'resolved-key')

      expect(Solargraph::PinCache).to have_received(:serialize_rbs_collection_gem).with(gemspec, 'resolved-key', [pin])
    end

    it 'builds YARD pins when the RBS collection cannot resolve types' do
      gemspec = cache_gem('parser', Solargraph::RbsMap::CACHE_KEY_UNRESOLVED)

      expect(Solargraph::PinCache).to have_received(:serialize_yard_gem).with(gemspec, [pin])
    end

    it 'builds YARD pins for a gem outside the suppression list' do
      gemspec = cache_gem('rspec', 'resolved-key')

      expect(Solargraph::PinCache).to have_received(:serialize_yard_gem).with(gemspec, [pin])
    end

    it 'warns when the gemspec is missing' do
      expect { shell.send(:do_cache, nil) }.to output(/not found/).to_stderr
    end
  end

  context 'with unbundled environments' do
    let!(:command_path) { File.realpath(File.join('spec', 'fixtures', 'shim.rb')) }
    let!(:unbundled_env) { Bundler.unbundled_env.merge({ 'BUNDLE_GEMFILE' => nil }) }

    describe '#cache' do
      it 'succeeds' do
        Dir.mktmpdir do |tmpdir|
          File.write(File.join(tmpdir, 'test.rb'), 'foo')
          _o, e, s = Open3.capture3(unbundled_env, 'ruby', command_path, 'cache', 'rspec', chdir: tmpdir)
          expect(s).to be_success, "expected success, got error with message #{e.inspect}"
        end
      end
    end

    describe '#gems' do
      it 'succeeds' do
        Dir.mktmpdir do |tmpdir|
          File.write(File.join(tmpdir, 'test.rb'), 'foo')
          _o, e, s = Open3.capture3(unbundled_env, 'ruby', command_path, 'gems', 'rspec', chdir: tmpdir)
          expect(s).to be_success, "expected success, got error with message #{e.inspect}"
        end
      end
    end

  describe 'rbs' do
    let(:api_map) { instance_double(Solargraph::ApiMap) }

    before do
      allow(shell).to receive(:`)
      allow(Solargraph::ApiMap).to receive(:load).and_return(api_map)
      allow(api_map).to receive(:source_maps).and_return(source_maps)
    end

    context 'without inference' do
      let(:source_maps) { [] }

      it 'invokes sord' do
        capture_both do
          shell.options = { filename: 'foo.rbs' }
          shell.rbs
        end
        expect(shell)
          .to have_received(:`)
          .with("sord #{Dir.pwd}/sig/foo.rbs --rbs --no-regenerate")
      end
    end

    context 'with inference' do
      let(:source_maps) { [source_map] }
      let(:source_map) { instance_double(Solargraph::SourceMap) }
      let(:pin) do
        instance_double(Solargraph::Pin::Method,
                        namespace: 'My::Namespace', path: 'My::Namespace#foo',
                        visibility: :public,
                        parameters: [],
                        scope: :instance,
                        location: nil,
                        name: 'foo',
                        class: Solargraph::Pin::Method,
                        return_type: Solargraph::ComplexType::UNDEFINED)
      end

      it 'infers unknown types on pins' do
        allow(source_map).to receive(:pins).and_return([pin])
        allow(pin).to receive_messages(typify: Solargraph::ComplexType.parse('String'),
                                       docstring: YARD::Docstring.new(''), macros: [])
        allow(pin).to receive(:code_object).and_return(nil)
        capture_both do
          shell.options = { filename: 'foo.rbs', inference: true }
          shell.rbs
        end
        expect(pin).to have_received(:typify)
      end
    end
  end
  end
end
