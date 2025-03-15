require 'tmpdir'
require 'yard'

describe Solargraph::Library do
  it "does not open created files in the workspace" do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      file_path = File.join(workspace_path, 'file.rb')
      File.write(file_path, 'a = b')
      library = Solargraph::Library.load(workspace_path)
      result = library.create(file_path, File.read(file_path))
      expect(result).to be(true)
      expect(library.open?(file_path)).to be(false)
    end
  end

  it "returns a Completion" do
    library = Solargraph::Library.new
    library.attach Solargraph::Source.load_string(%(
      x = 1
      x
    ), 'file.rb', 0)
    completion = library.completions_at('file.rb', 2, 7)
    expect(completion).to be_a(Solargraph::SourceMap::Completion)
    expect(completion.pins.map(&:name)).to include('x')
  end

  it "gets definitions from a file" do
    library = Solargraph::Library.new
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

  it "gets type definitions from a file" do
    library = Solargraph::Library.new
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

  it "signifies method arguments" do
    library = Solargraph::Library.new
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

  it "ignores invalid filenames in create_from_disk" do
    library = Solargraph::Library.new
    filename = 'not_a_real_file.rb'
    expect(library.create_from_disk(filename)).to be(false)
    expect(library.contain?(filename)).to be(false)
  end

  it "adds mergeable files to the workspace in create_from_disk" do
    Dir.mktmpdir do |temp_dir_path|
      # Ensure we resolve any symlinks to their real path
      workspace_path = File.realpath(temp_dir_path)
      library = Solargraph::Library.load(workspace_path)
      file_path = File.join(workspace_path, 'created.rb')
      File.write(file_path, "puts 'hello'")
      expect(library.create_from_disk(file_path)).to be(true)
      expect(library.contain?(file_path)).to be(true)
    end
  end

  it "ignores non-mergeable files in create_from_disk" do
    Dir.mktmpdir do |dir|
      library = Solargraph::Library.load(dir)
      filename = File.join(dir, 'created.txt')
      File.write(filename, "puts 'hello'")
      expect(library.create_from_disk(filename)).to be(false)
      expect(library.contain?(filename)).to be(false)
    end
  end

  it "diagnoses files" do
    library = Solargraph::Library.new
    src = Solargraph::Source.load_string(%(
      puts 'hello'
    ), 'file.rb', 0)
    library.attach src
    result = library.diagnose 'file.rb'
    expect(result).to be_a(Array)
    # @todo More tests
  end

  it "documents symbols" do
    library = Solargraph::Library.new
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

  it "collects references to an instance method symbol" do
    workspace = Solargraph::Workspace.new('*')
    library = Solargraph::Library.new(workspace)
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
    expect(locs.select{|l| l.filename == 'file2.rb' && l.range.start.line == 6}).to be_empty
  end

  it "collects references to a class method symbol" do
    workspace = Solargraph::Workspace.new('*')
    library = Solargraph::Library.new(workspace)
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
    expect(locs.select{|l| l.filename == 'file1.rb' && l.range.start.line == 2}).not_to be_empty
    expect(locs.select{|l| l.filename == 'file1.rb' && l.range.start.line == 9}).not_to be_empty
    expect(locs.select{|l| l.filename == 'file2.rb' && l.range.start.line == 1}).not_to be_empty
  end

  it "collects stripped references to constant symbols" do
    workspace = Solargraph::Workspace.new('*')
    library = Solargraph::Library.new(workspace)
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
      expect(code[o1..o2-1]).to eq('Foo')
    end
  end

  it 'rejects new references from different classes' do
    workspace = Solargraph::Workspace.new('*')
    library = Solargraph::Library.new(workspace)
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

  it "searches the core for queries" do
    library = Solargraph::Library.new
    result = library.search('String')
    expect(result).not_to be_empty
  end

  it "returns YARD documentation from the core" do
    library = Solargraph::Library.new
    result = library.document('String')
    expect(result).not_to be_empty
    expect(result.first).to be_a(Solargraph::Pin::Base)
  end

  it "returns YARD documentation from sources" do
    library = Solargraph::Library.new
    src = Solargraph::Source.load_string(%(
      class Foo
        # My bar method
        def bar; end
      end
    ), 'test.rb', 0)
    library.attach src
    result = library.document('Foo#bar')
    expect(result).not_to be_empty
    expect(result.first).to be_a(Solargraph::Pin::Base)
  end

  it "synchronizes sources from updaters" do
    library = Solargraph::Library.new
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

  it "finds unique references" do
    library = Solargraph::Library.new(Solargraph::Workspace.new('*'))
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

  it "includes method parameters in references" do
    library = Solargraph::Library.new(Solargraph::Workspace.new('*'))
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

  it "includes block parameters in references" do
    library = Solargraph::Library.new(Solargraph::Workspace.new('*'))
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

  it 'defines YARD tags' do
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
    source = Solargraph::Source.load_string(%(
      # String
      def foo; end
    ), 'test.rb')
    library.attach source
    pins = library.definitions_at('test.rb', 1, 14)
    expect(pins).to be_empty
  end

  it 'marks aliases as methods or attributes in completion items' do
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
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
    library = Solargraph::Library.new
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
      library = Solargraph::Library.load(workspace)
      library.map!
      location = Solargraph::Location.new(File.join(workspace, 'app.rb'), Solargraph::Range.from_to(0, 8, 0, 8))
      found = library.locate_ref(location)
      expect(found).to be_nil
    end
  end

  context 'unsynchronized' do
    let(:library) { Solargraph::Library.load File.absolute_path(File.join('spec', 'fixtures', 'workspace')) }
    let(:good_file) { File.join(library.workspace.directory, 'lib', 'thing.rb') }
    let(:bad_file) { File.join(library.workspace.directory, 'lib', 'not_a_thing.rb') }

    describe 'Library#completions_at' do
      it 'gracefully handles unmapped sources' do
        expect {
          library.completions_at(good_file, 0, 0)
        }.not_to raise_error
      end

      it 'raises errors for nonexistent sources' do
        expect {
          library.completions_at(bad_file, 0, 0)
        }.to raise_error(Solargraph::FileNotFoundError)
      end
    end

    describe 'Library#definitions_at' do
      it 'gracefully handles unmapped sources' do
        expect {
          library.definitions_at(good_file, 0, 0)
        }.not_to raise_error
      end

      it 'raises errors for nonexistent sources' do
        expect {
          library.definitions_at(bad_file, 0, 0)
        }.to raise_error(Solargraph::FileNotFoundError)
      end
    end
  end
end
