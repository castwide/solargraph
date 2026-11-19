# frozen_string_literal: true

require 'tmpdir'
require 'yard'
require 'timeout'

describe Solargraph::Library do
  it 'does not open created files in the workspace' do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      file_path = File.join(workspace_path, 'file.rb')
      File.write(file_path, 'a = b')
      library = described_class.load(workspace_path)
      result = library.create(file_path, File.read(file_path))
      expect(result).to be(true)
      expect(library.open?(file_path)).to be(false)
    end
  end

  it 'returns a Completion' do
    library = described_class.new
    library.attach Solargraph::Source.load_string(%(
      x = 1
      x
    ), 'file.rb', 0)
    completion = library.completions_at('file.rb', 2, 7)
    expect(completion).to be_a(Solargraph::SourceMap::Completion)
    expect(completion.pins.map(&:name)).to include('x')
  end

  context 'with a require from a not-yet-cached external gem' do
    before do
      metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport'))
      Solargraph::Collection::Gem.uncache(metagem)
    end

    it 'returns a Completion' do
      library = described_class.new(Solargraph::Workspace.new(Dir.pwd,
                                                              Solargraph::Workspace::Config.new))
      library.attach Solargraph::Source.load_string(%(
        require 'backport'

        # @param adapter [Backport::Adapter]
        def foo(adapter)
          adapter.remo
        end
      ), 'file.rb', 0)
      Timeout.timeout 60 do
        # give Solargraph time to cache the gem
        while (completion = library.completions_at('file.rb', 5, 19)).pins.empty?
          expect(library.send(:cache_errors)).to be_empty
          sleep 0.25
        end
        expect(completion).to be_a(Solargraph::SourceMap::Completion)
        expect(completion.pins.map(&:name)).to include('remote')
      end
    end
  end

  context 'with a require from a gem whose yardoc another process has locked' do
    let(:metagem) { Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport')) }
    let(:lock_file) { File.join(Solargraph::Yardoc.path_for(metagem), 'processing') }

    before do
      Solargraph::Collection::Gem.uncache(metagem)
      FileUtils.mkdir_p File.dirname(lock_file)
      FileUtils.touch lock_file
    end

    after do
      FileUtils.rm_f lock_file
    end

    it 'caches the gem anyway' do
      library = described_class.new(Solargraph::Workspace.new(Dir.pwd,
                                                              Solargraph::Workspace::Config.new))
      library.attach Solargraph::Source.load_string(%(
        require 'backport'

        # @param adapter [Backport::Adapter]
        def foo(adapter)
          adapter.remo
        end
      ), 'file.rb', 0)
      Timeout.timeout 60 do
        sleep 0.25 while (completion = library.completions_at('file.rb', 5, 19)).pins.empty?
        expect(completion.pins.map(&:name)).to include('remote')
      end
    end
  end

  context 'with a require from an already-cached external gem' do
    before do
      metagem = Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport'))
      Solargraph::Collection::Gem.load(metagem) unless Solargraph::Collection::Gem.cached?(metagem)
    end

    it 'returns a Completion' do
      library = described_class.new(Solargraph::Workspace.new(Dir.pwd,
                                                              Solargraph::Workspace::Config.new))
      library.attach Solargraph::Source.load_string(%(
        require 'backport'

        # @param adapter [Backport::Adapter]
        def foo(adapter)
          adapter.remo
        end
      ), 'file.rb', 0)
      completion = library.completions_at('file.rb', 5, 19)
      expect(completion).to be_a(Solargraph::SourceMap::Completion)
      expect(completion.pins.map(&:name)).to include('remote')
    end
  end

  it 'gets definitions from a file' do
    library = described_class.new
    src = Solargraph::Source.load_string %(
      class Foo
        def bar
        end
      end
    ), 'file.rb', 0
    library.attach src
    paths = library.definitions_at('file.rb', 2, 13).map(&:path)
    expect(paths).to include('Foo#bar')
  end

  it 'gets type definitions from a file' do
    library = described_class.new
    src = Solargraph::Source.load_string %(
      class Bar; end
      class Foo
        # @return [Bar]
        def self.bar
        end
      end
      Foo.bar
    ), 'file.rb', 0
    library.attach src
    paths = library.type_definitions_at('file.rb', 7, 13).map(&:path)
    expect(paths).to include('Bar')
  end

  it 'signifies method arguments' do
    library = described_class.new
    src = Solargraph::Source.load_string %(
      class Foo
        def bar baz, key: ''
        end
      end
      Foo.new.bar()
    ), 'file.rb', 0
    library.attach src
    pins = library.signatures_at('file.rb', 5, 18)
    expect(pins.length).to eq(1)
    expect(pins.first.path).to eq('Foo#bar')
  end

  it 'ignores invalid filenames in create_from_disk' do
    library = described_class.new
    filename = 'not_a_real_file.rb'
    expect(library.create_from_disk(filename)).to be(false)
    expect(library.contain?(filename)).to be(false)
  end

  it 'adds mergeable files to the workspace in create_from_disk' do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      library = described_class.load(workspace_path)
      file_path = File.join(workspace_path, 'created.rb')
      File.write(file_path, "puts 'hello'")
      expect(library.create_from_disk(file_path)).to be(true)
      expect(library.contain?(file_path)).to be(true)
    end
  end

  it 'ignores non-mergeable files in create_from_disk' do
    Dir.mktmpdir do |dir|
      library = described_class.load(dir)
      filename = File.join(dir, 'created.txt')
      File.write(filename, "puts 'hello'")
      expect(library.create_from_disk(filename)).to be(false)
      expect(library.contain?(filename)).to be(false)
    end
  end

  it 'diagnoses files' do
    library = described_class.new
    src = Solargraph::Source.load_string(%(
      puts 'hello'
    ), 'file.rb', 0)
    library.attach src
    result = library.diagnose 'file.rb'
    expect(result).to be_a(Array)
    # @todo More tests
  end

  it 'diagnoses using all reporters' do
    directory = ''
    config = instance_double(Solargraph::Workspace::Config)
    allow(config).to receive_messages(plugins: [], required: [], reporters: ['all!'])
    workspace = Solargraph::Workspace.new directory, config
    library = described_class.new workspace
    src = Solargraph::Source.load_string(%(
      puts 'hello'
    ), 'file.rb', 0)
    library.attach src
    result = library.diagnose 'file.rb'
    expect(result.to_s).to include('rubocop')
  end

  it 'documents symbols' do
    library = described_class.new
    src = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end
    ), 'file.rb', 0)
    library.attach src
    pins = library.document_symbols 'file.rb'
    expect(pins.length).to eq(2)
    expect(pins.map(&:path)).to include('Foo')
    expect(pins.map(&:path)).to include('Foo#bar')
  end

  describe '#references_from' do
    it 'collects references to a new method on a constant from assignment of Class.new' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      src1 = Solargraph::Source.load_string(%(
        Foo.new
      ), 'file1.rb', 0)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
        Foo = Class.new
      ), 'file2.rb', 0)
      library.merge src2
      library.catalog
      locs = library.references_from('file1.rb', 1, 12)
      expect(locs.map { |l| [l.filename, l.range.start.line] })
        .to eq([['file1.rb', 1]])
    end

    it 'collects references to a new method to a constant from assignment' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      src1 = Solargraph::Source.load_string(%(
        Foo.new
      ), 'file1.rb', 0)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
        class Foo
        end
        blah = Foo.new
      ), 'file2.rb', 0)
      library.merge src2
      library.catalog
      locs = library.references_from('file2.rb', 3, 21)
      expect(locs.map { |l| [l.filename, l.range.start.line] })
        .to eq([['file1.rb', 1], ['file2.rb', 3]])
    end

    it 'collects references to an instance method symbol' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      src1 = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end

      Foo.new.bar
    ), 'file1.rb', 0)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
      foo = Foo.new
      foo.bar
      class Other
        def bar; end
      end
      Other.new.bar
    ), 'file2.rb', 0)
      library.merge src2
      library.catalog
      locs = library.references_from('file2.rb', 2, 11)
      expect(locs.length).to eq(3)
      expect(locs.select { |l| l.filename == 'file2.rb' && l.range.start.line == 6 }).to be_empty
    end

    it 'collects references to a class method symbol' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      src1 = Solargraph::Source.load_string(%(
      class Foo
        def self.bar
        end

        def bar
        end
      end

      Foo.bar
      Foo.new.bar
    ), 'file1.rb', 0)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
      Foo.bar
      Foo.new.bar
      class Other
        def self.bar; end
        def bar; end
      end
      Other.bar
      Other.new.bar
    ), 'file2.rb', 0)
      library.merge src2
      library.catalog
      locs = library.references_from('file2.rb', 1, 11)
      expect(locs.length).to eq(3)
      expect(locs.select { |l| l.filename == 'file1.rb' && l.range.start.line == 2 }).not_to be_empty
      expect(locs.select { |l| l.filename == 'file1.rb' && l.range.start.line == 9 }).not_to be_empty
      expect(locs.select { |l| l.filename == 'file2.rb' && l.range.start.line == 1 }).not_to be_empty
    end

    it 'collects stripped references to constant symbols' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      src1 = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end
      Foo.new.bar
    ), 'file1.rb', 0)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
      class Other
        foo = Foo.new
        foo.bar
      end
    ), 'file2.rb', 0)
      library.merge src2
      library.catalog
      locs = library.references_from('file1.rb', 1, 12, strip: true)
      expect(locs.length).to eq(3)
      locs.each do |l|
        code = library.read_text(l.filename)
        o1 = Solargraph::Position.to_offset(code, l.range.start)
        o2 = Solargraph::Position.to_offset(code, l.range.ending)
        expect(code[o1..(o2 - 1)]).to eq('Foo')
      end
    end

    it 'rejects new references from different classes' do
      workspace = Solargraph::Workspace.new('*')
      library = described_class.new(workspace)
      source = Solargraph::Source.load_string(%(
      class Foo
        def bar
        end
      end
      Foo.new
      Array.new
    ), 'test.rb')
      library.merge source
      library.catalog
      foo_new_locs = library.references_from('test.rb', 5, 10)
      expect(foo_new_locs).to eq([Solargraph::Location.new('test.rb', Solargraph::Range.from_to(5, 10, 5, 13))])
      obj_new_locs = library.references_from('test.rb', 6, 12)
      expect(obj_new_locs).to eq([Solargraph::Location.new('test.rb', Solargraph::Range.from_to(6, 12, 6, 15))])
    end

    it 'searches the core for queries' do
      library = described_class.new
      result = library.search('String')
      expect(result).not_to be_empty
    end

    it 'returns YARD documentation from the core' do
      library = described_class.new
      _, result = library.document('String')
      expect(result).not_to be_empty
      expect(result.first).to be_a(Solargraph::Pin::Base)
    end

    it 'returns YARD documentation from sources' do
      library = described_class.new
      src = Solargraph::Source.load_string(%(
      class Foo
        # My bar method
        def bar; end
      end
    ), 'test.rb', 0)
      library.attach src
      _, result = library.document('Foo#bar')
      expect(result).not_to be_empty
      expect(result.first).to be_a(Solargraph::Pin::Base)
    end

    it 'synchronizes sources from updaters' do
      library = described_class.new
      src = Solargraph::Source.load_string(%(
      class Foo
      end
    ), 'test.rb', 1)
      library.attach src
      repl = %(
      class Foo
        def bar; end
      end
    )
      updater = Solargraph::Source::Updater.new(
        'test.rb',
        2,
        [Solargraph::Source::Change.new(nil, repl)]
      )
      library.attach src.synchronize(updater)
      expect(library.current.code).to eq(repl)
    end

    it 'finds unique references' do
      library = described_class.new(Solargraph::Workspace.new('*'))
      src1 = Solargraph::Source.load_string(%(
      class Foo
      end
    ), 'src1.rb', 1)
      library.merge src1
      src2 = Solargraph::Source.load_string(%(
      foo = Foo.new
    ), 'src2.rb', 1)
      library.merge src2
      library.catalog
      refs = library.references_from('src2.rb', 1, 12)
      expect(refs.length).to eq(2)
    end

    it 'includes method parameters in references' do
      library = described_class.new(Solargraph::Workspace.new('*'))
      source = Solargraph::Source.load_string(%(
      class Foo
        def bar(baz)
          baz.upcase
        end
      end
    ), 'test.rb', 1)
      library.attach source
      from_def = library.references_from('test.rb', 2, 16)
      expect(from_def.length).to eq(2)
      from_ref = library.references_from('test.rb', 3, 10)
      expect(from_ref.length).to eq(2)
    end

    it "lies about names when client can't handle the truth" do
      library = described_class.new(Solargraph::Workspace.new('*'))
      source = Solargraph::Source.load_string(%(
      class Foo
        def 🤦🏻foo♀️; 123; end
      end
    ), 'test.rb', 1)
      library.attach source
      from_def = library.references_from('test.rb', 2, 16, strip: true)
      expect(from_def.first.range.start.column).to eq(14)
    end

    it 'tells the truth about names when client can handle the truth' do
      library = described_class.new(Solargraph::Workspace.new('*'))
      source = Solargraph::Source.load_string(%(
      class Foo
        def 🤦🏻foo♀️; 123; end
      end
    ), 'test.rb', 1)
      library.attach source
      from_def = library.references_from('test.rb', 2, 16, strip: false)
      expect(from_def.first.range.start.column).to eq(12)
    end

    it 'includes block parameters in references' do
      library = described_class.new(Solargraph::Workspace.new('*'))
      source = Solargraph::Source.load_string(%(
      100.times do |foo|
        puts foo
      end
    ), 'test.rb', 1)
      library.attach source
      from_def = library.references_from('test.rb', 1, 20)
      expect(from_def.length).to eq(2)
      from_ref = library.references_from('test.rb', 2, 13)
      expect(from_ref.length).to eq(2)
    end
  end

  it 'defines YARD tags' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class TaggedExample
      end
      class CallerExample
        # @return [TaggedExample]
        def foo; end
      end
    ), 'test.rb')
    library.attach source
    # Start of tag
    pins = library.definitions_at('test.rb', 4, 19)
    expect(pins.map(&:path)).to include('TaggedExample')
    # Middle of tag
    pins = library.definitions_at('test.rb', 4, 25)
    expect(pins.map(&:path)).to include('TaggedExample')
    # End of tag
    pins = library.definitions_at('test.rb', 4, 32)
    expect(pins.map(&:path)).to include('TaggedExample')
  end

  it 'defines YARD tags with nested namespaces' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class Tagged
        class Example; end
      end
      class CallerExample
        # @return [Tagged::Example]
        def foo; end
      end
    ), 'test.rb')
    library.attach source
    pins = library.definitions_at('test.rb', 5, 19)
    expect(pins.map(&:path)).to include('Tagged')
    pins = library.definitions_at('test.rb', 5, 26)
    expect(pins.map(&:path)).to include('Tagged')
    pins = library.definitions_at('test.rb', 5, 27)
    expect(pins.map(&:path)).to include('Tagged::Example')
  end

  it 'defines generic YARD tags' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class TaggedExample; end
      class CallerExample
        # @return [Array<TaggedExample>]
        def foo; end
      end
    ), 'test.rb')
    library.attach source
    pins = library.definitions_at('test.rb', 3, 31)
    expect(pins.map(&:path)).to include('TaggedExample')
  end

  it 'defines multiple YARD tags' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class TaggedExample; end
      class CallerExample
        # @return [TaggedExample, String]
        def foo; end
      end
    ), 'test.rb')
    library.attach source
    pins = library.definitions_at('test.rb', 3, 31)
    expect(pins.map(&:path)).to include('TaggedExample')
  end

  it 'skips comment text outside of tags' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      # String
      def foo; end
    ), 'test.rb')
    library.attach source
    pins = library.definitions_at('test.rb', 1, 14)
    expect(pins).to be_empty
  end

  it 'marks aliases as methods or attributes in completion items' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class Example
        attr_reader :foo
        def bar; end

        alias foo_alias foo
        alias bar_alias bar

        def baz
          foo_
          bar_
        end
      end
    ), 'test.rb')
    library.attach source
    foo_alias = library.completions_at('test.rb', 9, 14).pins.first
    expect(foo_alias.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::PROPERTY)
    bar_alias = library.completions_at('test.rb', 10, 14).pins.first
    expect(bar_alias.completion_item_kind).to eq(Solargraph::LanguageServer::CompletionItemKinds::METHOD)
  end

  it 'marks aliases as methods or attributes in definitions' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class Example
        attr_reader :foo
        def bar; end

        alias foo_alias foo
        alias bar_alias bar
      end
    ), 'test.rb')
    library.attach source
    pins = library.document_symbols('test.rb')
    foo_alias = pins.select { |pin| pin.name == 'foo_alias' }.first
    expect(foo_alias.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::PROPERTY)
    bar_alias = pins.select { |pin| pin.name == 'bar_alias' }.first
    expect(bar_alias.symbol_kind).to eq(Solargraph::LanguageServer::SymbolKinds::METHOD)
  end

  it 'detaches current source with nil' do
    library = described_class.new
    source = Solargraph::Source.load_string(%(
      class Example
        attr_reader :foo
        def bar; end

        alias foo_alias foo
        alias bar_alias bar
      end
    ), 'test.rb')
    library.attach source
    library.attach nil
    expect(library.current).to be_nil
  end

  describe '#locate_ref' do
    it 'returns nil without a matching reference location' do
      workspace = File.absolute_path(File.join('spec', 'fixtures', 'workspace'))
      library = described_class.load(workspace)
      library.map!
      location = Solargraph::Location.new(File.join(workspace, 'app.rb'), Solargraph::Range.from_to(0, 8, 0, 8))
      found = library.locate_ref(location)
      expect(found).to be_nil
    end
  end

  describe '#delete' do
    it 'removes files from Library#source_map_hash' do
      workspace = File.absolute_path(File.join('spec', 'fixtures', 'workspace'))
      library = described_class.load(workspace)
      library.map!
      library.catalog
      other_file = File.absolute_path(File.join('spec', 'fixtures', 'workspace', 'lib', 'other.rb'))

      expect(library.source_map_hash.key?(other_file)).to be(true)
      pins = library.get_path_pins('Other')
      expect(pins).to be_one

      library.delete other_file
      library.catalog
      expect(library.source_map_hash.key?(other_file)).to be(false)
      pins = library.get_path_pins('Other')
      expect(pins).to be_empty
    end
  end

  context 'when unsynchronized' do
    let(:library) { described_class.load File.absolute_path(File.join('spec', 'fixtures', 'workspace')) }
    let(:good_file) { File.join(library.workspace.directory, 'lib', 'thing.rb') }
    let(:bad_file) { File.join(library.workspace.directory, 'lib', 'not_a_thing.rb') }

    describe 'Library#completions_at' do
      it 'gracefully handles unmapped sources' do
        expect do
          library.completions_at(good_file, 0, 0)
        end.not_to raise_error
      end

      it 'raises errors for nonexistent sources' do
        expect do
          library.completions_at(bad_file, 0, 0)
        end.to raise_error(Solargraph::FileNotFoundError)
      end
    end

    describe 'Library#definitions_at' do
      it 'gracefully handles unmapped sources' do
        expect do
          library.definitions_at(good_file, 0, 0)
        end.not_to raise_error
      end

      it 'raises errors for nonexistent sources' do
        expect do
          library.definitions_at(bad_file, 0, 0)
        end.to raise_error(Solargraph::FileNotFoundError)
      end
    end
  end

  describe '#cache_next_gemspec' do
    let(:library) { described_class.new(Solargraph::Workspace.new(Dir.pwd, Solargraph::Workspace::Config.new)) }
    let(:metagem) { Solargraph::Metagem.from_specification(Gem::Specification.find_by_name('backport')) }
    let(:cache_threads) { [] }

    before do
      api_map = library.send(:api_map)
      allow(api_map).to receive(:catalog)
      allow(api_map).to receive(:unloaded_gems).and_return(Set[metagem])
      allow(Thread).to receive(:new).and_wrap_original do |original, *args, &block|
        original.call(*args, &block).tap { |thread| cache_threads.push thread }
      end
    end

    # Join the cache threads, stopping after a few in case they respawn
    # forever.
    def join_cache_threads
      5.times do
        thread = cache_threads.shift
        break unless thread
        thread.join
      end
    end

    it 'does not retry a gem whose cache command failed' do
      status = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).and_return(['', 'error', status])

      library.catalog
      library.send(:sync_catalog)
      join_cache_threads

      expect(Open3).to have_received(:capture3).once
    end

    it 'finishes caching when an unexpected error is raised' do
      allow(Open3).to receive(:capture3).and_raise('cache failed')

      library.catalog
      library.send(:sync_catalog)
      join_cache_threads

      expect(library.cache_progress).to be_nil
    end

    it 'finishes caching when the cache command cannot run' do
      allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

      library.catalog
      library.send(:sync_catalog)
      join_cache_threads

      expect(library.cache_progress).to be_nil
    end
  end

  describe '#definitions_at on a variable' do
    let(:library) { described_class.new }

    # @param code [String]
    # @param line [Integer]
    # @param column [Integer]
    # @return [Array<Array(Integer, Integer)>] the start line and column of each definition
    def definition_starts code, line, column
      library.attach Solargraph::Source.load_string(code, 'test.rb')
      library.definitions_at('test.rb', line, column).map { |pin| [pin.location.range.start.line, pin.location.range.start.character] }
    end

    it 'lists every assignment of an instance variable in the class, by file and line' do
      starts = definition_starts(<<~RUBY_CODE, 14, 4)
        class Foo
          def create
            @post = 1
          end

          def set_post
            @post = 2
          end

          def new
            @post = 3
          end

          def show
            @post
          end
        end
      RUBY_CODE
      expect(starts).to eq([[2, 4], [6, 4], [10, 4]])
    end

    it 'lists a local assigned in both branches of an if' do
      starts = definition_starts(<<~RUBY_CODE, 6, 2)
        def foo
          if rand
            x = 1
          else
            x = 'one'
          end
          x
        end
      RUBY_CODE
      expect(starts).to eq([[2, 4], [4, 4]])
    end

    it 'jumps straight to a single assignment' do
      starts = definition_starts(<<~RUBY_CODE, 2, 2)
        def foo
          x = 1
          x
        end
      RUBY_CODE
      expect(starts).to eq([[1, 2]])
    end

    it 'leaves out an assignment not visible at the cursor' do
      starts = definition_starts(<<~RUBY_CODE, 6, 2)
        def foo
          x = 1
        end

        def bar
          x = 2
          x
        end
      RUBY_CODE
      expect(starts).to eq([[5, 2]])
    end

    context 'with a pin that stands for several definitions' do
      # The convention adds an `@origin` to Foo#show in test.rb whose definitions
      # are assignments in other.rb, the way solargraph-rails copies a controller's
      # ivars into its views:
      #
      #   # other.rb
      #   line 3:   @origin = 'a'   (column 2)
      #   line 9: @origin = 'b'     (column 0, listed twice to check it is deduplicated)
      #
      #   # test.rb
      #   class Foo
      #     def show
      #       @origin   # go to definition lists other.rb:3 and other.rb:9
      #     end
      #   end
      let(:convention) do
        Class.new(Solargraph::Convention::Base) do
          def local source_map
            return Solargraph::Environ.new unless source_map.filename == 'test.rb'

            origin = Class.new(Solargraph::Pin::InstanceVariable) do
              def definition_locations
                [[9, 0], [3, 2], [9, 0]].map do |line, column|
                  Solargraph::Location.new('other.rb', Solargraph::Range.from_to(line, column, line, column + 6))
                end
              end
            end
            show = Solargraph::Pin::Method.new(name: 'show', closure: Solargraph::Pin::Namespace.new(name: 'Foo'),
                                               scope: :instance, source: :spec)
            Solargraph::Environ.new(pins: [
                                      origin.new(name: '@origin', closure: show, source: :spec,
                                                 location: Solargraph::Location.new('test.rb', Solargraph::Range.from_to(0, 0, 0, 3)),
                                                 return_type: Solargraph::ComplexType.parse('String'))
                                    ])
          end
        end
      end

      before { Solargraph::Convention.register convention }

      after { Solargraph::Convention.unregister convention }

      it 'lists each of its locations' do
        library.attach Solargraph::Source.load_string(<<~RUBY_CODE, 'test.rb')
          class Foo
            def show
              @origin
            end
          end
        RUBY_CODE
        locations = library.definitions_at('test.rb', 2, 4).map(&:location)
        expect(locations.map { |loc| [loc.filename, loc.range.start.line] }).to eq([['other.rb', 3], ['other.rb', 9]])
      end
    end
  end
end
